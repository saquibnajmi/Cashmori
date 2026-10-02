import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backup_service.dart';
import '../theme/app_theme.dart';

const String _mySavingSummaryVisibleKey = 'my_saving_summary_visible';

// Settings area for backup and restore actions.
// It gives users a safe way to export or recover the app database and custom categories.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  bool _showSummaryByDefault = true;

  @override
  void initState() {
    super.initState();
    _loadSummaryPreference();
  }

  /// Loads the stored My Saving summary preference used as the default for new sessions.
  Future<void> _loadSummaryPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _showSummaryByDefault =
        prefs.getBool(_mySavingSummaryVisibleKey) ?? true);
  }

  /// Saves the default visibility value for the My Saving summary and updates the UI state.
  Future<void> _updateSummaryPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mySavingSummaryVisibleKey, value);
    if (!mounted) return;
    setState(() => _showSummaryByDefault = value);
  }

  /// Shows a blocking progress dialog while a backup or restore operation is running.
  Future<void> _showBusyDialog(String title, {String? subtitle}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a zip backup and reports a human-friendly file name back to the user.
  /// The path is normalized first so Android document URIs do not show random IDs like 71.
  Future<void> _backup() async {
    try {
      final outputPath = await BackupService.backupToZip(forceFilePicker: true);
      if (!mounted) return;
      final backupName = BackupService.fileNameForDisplay(outputPath);
      _snack(
        backupName == null
            ? 'Backup successful.'
            : 'Backup successful: $backupName',
      );
    } catch (e) {
      _snack('Back up failed: $e');
    }
  }

  /// Lets the user choose a backup file to restore and confirms the destructive action.
  Future<void> _showRestorePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result.isEmpty) {
      _snack('No backup file selected.');
      return;
    }

    final file = result.first;
    final filePath = file.path;
    if (filePath == null || filePath.isEmpty) {
      _snack('This backup file could not be read.');
      return;
    }

    final backupBytes = await File(filePath).readAsBytes();
    final backupName = file.name;
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          '$backupName\n\nThe current records, categories, budgets and accounts will be deleted and the backup will be restored. Are you really sure?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESTORE NOW'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      if (!mounted) return;
      _showBusyDialog('Restoring backup…',
          subtitle: 'Please wait while your data is restored');
      final restored = await BackupService.restoreFromZipBytes(backupBytes);
      if (!mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _snack(restored ? 'Restore complete.' : 'Restore cancelled.');
    } catch (e) {
      if (mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      _snack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Displays a short snackbar message for backup and restore feedback.
  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Renders the backup and restore screen with prompts for saving and restoring data.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Show My Saving summary By-Default',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _showSummaryByDefault,
                    activeThumbColor: AppColors.accent,
                    onChanged: (value) => _updateSummaryPreference(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup & Restore',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'A backup file contains all records, categories, accounts and budgets at the time it was created. It can be used to restore your data if the device is lost or the app is uninstalled.',
                    style: TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Press Backup Now to choose a save location and create a backup file.\n• Press Restore to choose an existing backup file and restore it.\n• Keep the newest backup file in a safe place such as your computer or cloud storage.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _backup,
                        icon: const Icon(Icons.upload_file, size: 22),
                        label: const Text('BACKUP NOW'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _showRestorePicker,
                        icon: const Icon(Icons.download_rounded, size: 22),
                        label: const Text('RESTORE'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                            color: AppColors.textPrimary,
                            width: 1.5,
                          ),
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 14),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
