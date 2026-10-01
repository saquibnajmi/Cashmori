import 'package:cashmori/utils/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
