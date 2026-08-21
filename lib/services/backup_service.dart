import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database_helper.dart';

/// Handles exporting the live SQLite file as a .zip the user can save
/// anywhere (Drive, phone storage, email, etc.), and restoring from one.
///
/// Why zip a raw .db file instead of JSON?
/// - It's an exact byte-for-byte copy of every table (transactions,
///   borrow records, shares, assets) in one shot - nothing can be missed.
/// - Restore is just "stop app -> replace file -> reopen db", no need to
///   re-parse / re-insert thousands of rows.
class BackupService {
  static const String backupFileName = 'money_tracker_backup.zip';

  /// Creates money_tracker_backup.zip in the app's temp dir containing the
  /// current money_tracker.db, then opens the native share/save sheet so
  /// the user can put it wherever they like (Downloads, Drive, etc.).
  static Future<String> backupToZip() async {
    final dbPath = await DatabaseHelper.instance.getDbPath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('No database found yet — add at least one entry first.');
    }

    // Make sure everything is flushed to disk before we copy it.
    await DatabaseHelper.instance.closeDb();

    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/$backupFileName';

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addFile(dbFile, 'money_tracker.db');
    encoder.close();

    // Reopen the db for the running app since we closed it above.
    await DatabaseHelper.instance.database;

    // Hand the file to the OS share sheet -> user picks "Save to Files",
    // Drive, email, etc. This doubles as the "export" action.
    await Share.shareXFiles([XFile(zipPath)], text: 'Money Tracker backup');

    return zipPath;
  }

  /// Lets the user pick a previously exported .zip, extracts money_tracker.db
  /// from it, and overwrites the app's live database with it.
  /// Returns true if a restore was performed.
  static Future<bool> restoreFromZip() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    // `FilePicker.pickFiles` on the currently-resolved package version
    // returns `List<PlatformFile>` so handle that shape directly.
    if (result.isEmpty) return false;
    final PlatformFile first = result.first;
    if (first.path == null) return false;
    final pickedZip = File(first.path!);
    final bytes = await pickedZip.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? dbEntry;
    for (final f in archive) {
      if (f.name == 'money_tracker.db') {
        dbEntry = f;
        break;
      }
    }
    if (dbEntry == null) {
      throw Exception(
          'This zip does not contain a valid money_tracker.db backup.');
    }

    // Close the live db before overwriting the file on disk.
    await DatabaseHelper.instance.closeDb();

    final dbPath = await DatabaseHelper.instance.getDbPath();
    final targetFile = File(dbPath);
    await targetFile.writeAsBytes(dbEntry.content as List<int>, flush: true);

    // Reopen with the restored data.
    await DatabaseHelper.instance.database;

    return true;
  }
}
