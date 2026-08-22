import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showBusyDialog(String title, {String? subtitle}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
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

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      _showBusyDialog('Backing up…', subtitle: 'Creating your backup file');
      final outputPath = await BackupService.backupToZip();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final backupName = File(outputPath).uri.pathSegments.last;
      _snack('Backup successful: $backupName');
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _snack('Back up failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
      Navigator.of(context, rootNavigator: true).pop();
      _snack(restored ? 'Restore complete.' : 'Restore cancelled.');
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _snack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
