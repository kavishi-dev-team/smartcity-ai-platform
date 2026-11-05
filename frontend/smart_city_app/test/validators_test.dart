import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('kamal@example.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('phone', () {
      expect(Validators.phone('0771234567'), isNull);
      expect(Validators.phone('+94 77 123 4567'), isNull);
      expect(Validators.phone('12345'), isNotNull);
    });

    test('newPassword matches backend rules', () {
      expect(Validators.newPassword('Password@123'), isNull);
      expect(Validators.newPassword('short1A'), isNotNull);
      expect(Validators.newPassword('alllowercase1'), isNotNull);
      expect(Validators.newPassword('ALLUPPERCASE1'), isNotNull);
      expect(Validators.newPassword('NoDigitsHere'), isNotNull);
    });

    test('confirmPassword', () {
      final validator = Validators.confirmPassword(() => 'Password@123');
      expect(validator('Password@123'), isNull);
      expect(validator('different'), isNotNull);
    });

    test('passwordStrength', () {
      expect(Validators.passwordStrength(''), 0);
      expect(Validators.passwordStrength('Password@123'), 4);
    });
  });
}