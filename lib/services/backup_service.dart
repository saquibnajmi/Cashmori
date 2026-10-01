import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import 'custom_subcategory_service.dart';

class BackupFileInfo {
  final File file;
  final DateTime modified;

  BackupFileInfo(this.file, this.modified);

  String get name => file.uri.pathSegments.last;
}

/// Handles exporting the live SQLite file as a .zip the user can save
/// anywhere (Drive, phone storage, email, etc.), and restoring from one.
///
/// Why zip a raw .db file instead of JSON?
/// - It's an exact byte-for-byte copy of every table (transactions,
///   borrow records, shares, assets) in one shot - nothing can be missed.
/// - Restore is just "stop app -> replace file -> reopen db", no need to
///   re-parse / re-insert thousands of rows.
class BackupService {
  static const String _selectedDirKey = 'backup_selected_directory';

  static String? normalizeSelectedDirectoryPath(String? path) {
    if (path == null) return null;

    final cleaned = path.trim();
    if (cleaned.isEmpty) return null;

    if (cleaned.startsWith('content://')) return null;
    if (cleaned.startsWith('file://')) return null;

    final isWindowsAbsolute = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(cleaned);
    if (cleaned.startsWith('/') || isWindowsAbsolute) {
      return cleaned;
    }

    return null;
  }

  static bool isFileSystemDirectoryPath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('content://')) return false;
    if (path.startsWith('file://')) return false;
    return path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }

  static Future<String?> getSelectedDirectoryPath() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_selectedDirKey);
    final normalized = normalizeSelectedDirectoryPath(saved);

    if (saved != null && normalized == null) {
      await prefs.remove(_selectedDirKey);
      return null;
    }

    return normalized;
  }

  static Future<void> setSelectedDirectoryPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalizeSelectedDirectoryPath(path);

    if (normalized == null) {
      await prefs.remove(_selectedDirKey);
      return;
    }

    await prefs.setString(_selectedDirKey, normalized);
  }

  static Future<String?> pickDirectory() async {
    final result = await FilePicker.getDirectoryPath();
    final normalized = normalizeSelectedDirectoryPath(result);
    if (normalized == null) return null;
    await setSelectedDirectoryPath(normalized);
    return normalized;
  }

  static Future<List<BackupFileInfo>> listAvailableBackups(
      {String? directoryPath}) async {
    final target = directoryPath ?? await getSelectedDirectoryPath();
    if (target == null ||
        target.isEmpty ||
        !isFileSystemDirectoryPath(target)) {
      return const [];
    }

    final dir = Directory(target);
    if (!await dir.exists()) return const [];

    final files = await dir.list().where((entity) {
      if (entity is! File) return false;
      final name = entity.path.toLowerCase();
      return name.endsWith('.zip');
    }).toList();

    final backups = files
        .map((entity) => BackupFileInfo(
              entity as File,
              entity.statSync().modified,
            ))
        .toList();

    backups.sort((a, b) => b.modified.compareTo(a.modified));
    return backups;
  }

  static Future<File?> pickBackupFile({String? initialDirectory}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      initialDirectory:
          isFileSystemDirectoryPath(initialDirectory) ? initialDirectory : null,
    );
    if (result.isEmpty) return null;
    final filePath = result.first.path;
    if (filePath == null || filePath.isEmpty) return null;
    return File(filePath);
  }

  static Future<bool> restoreBackup(BackupFileInfo backup) async {
    return restoreFromZip(backup.file);
  }

  static Future<String> backupToZip(
      {String? directoryPath, bool forceFilePicker = false}) async {
    final dbPath = await DatabaseHelper.instance.getDbPath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('No database found yet — add at least one entry first.');
    }

    final selectedPath = directoryPath ?? await getSelectedDirectoryPath();
    final targetDirPath =
        forceFilePicker ? null : normalizeSelectedDirectoryPath(selectedPath);
    final fileName =
        'cashmori_Backup_${DateFormat('dd_MM_yy_HHmm').format(DateTime.now())}.zip';
    final tempDir = await getTemporaryDirectory();
    final tempZipPath = '${tempDir.path}/$fileName';

    await DatabaseHelper.instance.closeDb();

    try {
      final customSnapshot = await CustomSubcategoryService.snapshot();
      final encoder = ZipFileEncoder();
      encoder.create(tempZipPath);
      encoder.addFile(dbFile, 'money_tracker.db');

      final payload = Map<String, dynamic>.from(customSnapshot);
      final jsonBytes = utf8.encode(jsonEncode(payload));
      final tempJsonFile =
          File('${tempDir.path}/__cashmori_custom_subcategories.json');
      await tempJsonFile.writeAsBytes(jsonBytes, flush: true);
      encoder.addFile(tempJsonFile, 'custom_subcategories.json');
      await tempJsonFile.delete();
      encoder.close();

      if (!forceFilePicker &&
          targetDirPath != null &&
          targetDirPath.isNotEmpty) {
        final targetDir = Directory(targetDirPath);
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        final finalZip = File(tempZipPath);
        final targetZip = File('${targetDir.path}/$fileName');
        await finalZip.copy(targetZip.path);

        await DatabaseHelper.instance.database;
        return targetZip.path;
      }

      final bytes = await File(tempZipPath).readAsBytes();
      final chosen = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (chosen == null) {
        throw Exception('Backup was canceled.');
      }

      await DatabaseHelper.instance.database;
      return chosen.path.isEmpty ? fileName : chosen.path;
    } catch (e) {
      await DatabaseHelper.instance.database;
      rethrow;
    }
  }

  static Future<bool> restoreFromZip(File zipFile) async {
    if (!await zipFile.exists()) return false;
    final bytes = await zipFile.readAsBytes();
    return restoreFromZipBytes(bytes);
  }

  static Future<bool> restoreFromZipBytes(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? dbEntry;
    ArchiveFile? subcategoryEntry;
    for (final f in archive) {
      if (f.name == 'money_tracker.db') {
        dbEntry = f;
      } else if (f.name == 'custom_subcategories.json') {
        subcategoryEntry = f;
      }
    }

    if (dbEntry == null) {
      throw Exception(
          'This zip does not contain a valid money_tracker.db backup.');
    }

    await DatabaseHelper.instance.closeDb();

    try {
      final dbPath = await DatabaseHelper.instance.getDbPath();
      final targetFile = File(dbPath);
      await targetFile.writeAsBytes(dbEntry.content as List<int>, flush: true);

      if (subcategoryEntry != null) {
        final content = utf8.decode(subcategoryEntry.content as List<int>);
        if (content.trim() != '{}' && content.trim() != 'null') {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          final map = <String, List<String>>{};
          decoded.forEach((key, value) {
            if (value is List) {
              map[key] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              // Older formats or accidental stringification may store
              // subcategories as a pipe-separated string (e.g. "a|b|c").
              // Try to decode a JSON-encoded list first, otherwise split.
              try {
                final maybeList = jsonDecode(value);
                if (maybeList is List) {
                  map[key] = maybeList.map((e) => e.toString()).toList();
                  return;
                }
              } catch (_) {}

              final parts = value
                  .split('|')
                  .map((e) => e.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (parts.isNotEmpty) map[key] = parts;
            }
          });
          await CustomSubcategoryService.clearAll();
          await CustomSubcategoryService.restore(map);
        }
      }

      await DatabaseHelper.instance.database;
      return true;
    } catch (_) {
      await DatabaseHelper.instance.database;
      rethrow;
    }
  }
}
