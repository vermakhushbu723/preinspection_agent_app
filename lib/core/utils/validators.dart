/// Field validators ported from `OwnerVehicleDetailsPage.jsx`'s inline
/// validation rules.
class Validators {
  Validators._();

  static final RegExp _mobileExp = RegExp(r'^\d{10}$');
  static final RegExp _emailExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _lettersOnlyExp = RegExp(r'^[a-zA-Z\s]*$');
  static final RegExp _plateExp = RegExp(r'^[a-zA-Z0-9]*$');
  static final RegExp _digitsOnlyExp = RegExp(r'^\d*$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? mobile(String? value) {
    final err = required(value, field: 'Mobile number');
    if (err != null) return err;
    if (!_mobileExp.hasMatch(value!.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? email(String? value) {
    final err = required(value, field: 'Email');
    if (err != null) return err;
    if (!_emailExp.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static bool isLettersOnly(String value) => _lettersOnlyExp.hasMatch(value);

  static bool isPlateChar(String value) => _plateExp.hasMatch(value);

  static bool isDigitsOnly(String value) => _digitsOnlyExp.hasMatch(value);
}
