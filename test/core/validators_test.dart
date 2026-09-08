import 'package:flutter_test/flutter_test.dart';
import 'package:preinspection_agent_app/core/utils/validators.dart';

void main() {
  group('Validators.mobile', () {
    test('rejects empty input', () {
      expect(Validators.mobile(''), isNotNull);
    });

    test('rejects non 10-digit numbers', () {
      expect(Validators.mobile('12345'), isNotNull);
      expect(Validators.mobile('123456789012'), isNotNull);
    });

    test('accepts a valid 10-digit number', () {
      expect(Validators.mobile('9876543210'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('owner@example.com'), isNull);
    });
  });

  group('character filters', () {
    test('isLettersOnly allows letters and spaces only', () {
      expect(Validators.isLettersOnly('Rahul Sharma'), isTrue);
      expect(Validators.isLettersOnly('Rahul123'), isFalse);
    });

    test('isDigitsOnly allows digits only', () {
      expect(Validators.isDigitsOnly('12345'), isTrue);
      expect(Validators.isDigitsOnly('123a5'), isFalse);
    });

    test('isPlateChar allows alphanumeric only', () {
      expect(Validators.isPlateChar('OD02AB1234'), isTrue);
      expect(Validators.isPlateChar('OD-02'), isFalse);
    });
  });
}
