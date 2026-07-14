import 'package:flutter_test/flutter_test.dart';
import 'package:egbeanom/models/validators.dart';

void main() {
  group('Validators', () {
    test('validateEmail accepts valid and rejects invalid values', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('invalid'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('validatePrice enforces numeric positive range', () {
      expect(Validators.validatePrice(19.99), isNull);
      expect(Validators.validatePrice(0), isNotNull);
      expect(Validators.validatePrice(-1), isNotNull);
      expect(Validators.validatePrice('abc'), isNotNull);
    });

    test('validateZipCode validates US ZIP formats', () {
      expect(Validators.validateZipCode('12345'), isNull);
      expect(Validators.validateZipCode('12345-6789'), isNull);
      expect(Validators.validateZipCode('1234'), isNotNull);
    });

    test('validateAddress checks required fields', () {
      expect(
        Validators.validateAddress('123 Main St', 'Atlanta', 'GA', '30303'),
        isNull,
      );
      expect(
        Validators.validateAddress('', 'Atlanta', 'GA', '30303'),
        isNotNull,
      );
    });

    test('validateQuantity and inventory checks', () {
      expect(Validators.validateQuantity(1), isNull);
      expect(Validators.validateQuantity(0), isNotNull);
      expect(Validators.validateInventoryAvailable(2, 3), isNotNull);
      expect(Validators.validateInventoryAvailable(3, 2), isNull);
    });

    test('validateState and validatePhone enforce US formats', () {
      expect(Validators.validateState('GA'), isNull);
      expect(Validators.validateState('XX'), isNotNull);
      expect(Validators.validatePhone('404-555-1212'), isNull);
      expect(Validators.validatePhone('1234'), isNotNull);
    });

    test('validateCouponCode validates alphanumeric length constraints', () {
      expect(Validators.validateCouponCode('SAVE10'), isNull);
      expect(Validators.validateCouponCode('ab'), isNotNull);
      expect(Validators.validateCouponCode('BAD CODE'), isNotNull);
    });

    test('account password and verification code validators are covered', () {
      expect(Validators.validatePassword('StrongPass1'), isNull);
      expect(Validators.validatePassword('short1A'), isNotNull);
      expect(Validators.validatePassword('lowercase1'), isNotNull);
      expect(Validators.validatePassword('UPPERCASE1'), isNotNull);
      expect(Validators.validatePassword('NoNumberHere'), isNotNull);

      expect(Validators.validateVerificationCode('ABC123'), isNull);
      expect(Validators.validateVerificationCode('1234567890'), isNull);
      expect(Validators.validateVerificationCode('bad code'), isNotNull);
      expect(Validators.validateVerificationCode('123'), isNotNull);
    });
  });
}
