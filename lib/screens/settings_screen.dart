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

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await BackupService.backupToZip();
      _snack('Backup ready — choose where to save it.');
    } catch (e) {
      _snack('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
            'This will replace ALL current data (transactions, borrow records, shares, assets) with the contents of the backup file. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final restored = await BackupService.restoreFromZip();
      _snack(restored
          ? 'Restore complete. Restart the app to see all changes.'
          : 'Cancelled.');
    } catch (e) {
      _snack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                  const Text('BACKUP & RESTORE',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text(
                    'Your data lives only on this device. Export a backup file regularly and store it somewhere safe (Drive, email to yourself, etc.) — restoring will overwrite everything currently on the device.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _backup,
                    icon: const Icon(Icons.upload_file, size: 28),
                    label: const Text('BACKUP NOW'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.download_rounded, size: 28),
                    label: const Text('RESTORE FROM FILE'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                          color: AppColors.textPrimary, width: 1.5),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
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
