import 'dart:convert';

import 'package:cashmori/services/backup_service.dart';
import 'package:cashmori/utils/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

// Basic regression tests ensuring validation and backup filename rules remain stable.
void main() {
  group('AppValidators', () {
    test('required field validation returns message for empty input', () {
      expect(AppValidators.required('   '), 'Please fill this field.');
      expect(AppValidators.required('Jane'), isNull);
    });

    test('positive number validation rejects zero and negatives', () {
      expect(AppValidators.positiveNumber('0'),
          'Enter a valid amount greater than zero.');
      expect(AppValidators.positiveNumber('-5'),
          'Enter a valid amount greater than zero.');
      expect(AppValidators.positiveNumber('12.5'), isNull);
    });
  });

  group('BackupService', () {
    test('extracts real filenames and ignores Android document ids', () {
      expect(
        BackupService.fileNameForDisplay(
            '/storage/emulated/0/Download/cashmori_Backup_20_10_26_1234.zip'),
        'cashmori_Backup_20_10_26_1234.zip',
      );

      expect(
        BackupService.fileNameForDisplay(
            'content://com.android.providers.downloads.documents/document/71'),
        isNull,
      );

      expect(
        BackupService.fileNameForDisplay('/storage/emulated/0/Documents/71'),
        isNull,
      );
    });

    test('converts archived string content into bytes safely', () {
      final bytes = BackupService.archiveContentAsBytes('{"key":["a","b"]}');
      expect(bytes, utf8.encode('{"key":["a","b"]}'));
    });
  });
}
