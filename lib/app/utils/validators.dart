import 'package:get/get_utils/src/get_utils/get_utils.dart';

class Validators {
  static String? requiredField(String? value, String name) {
    if (value == null || value.trim().isEmpty) return '$name is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(value.trim())) return 'Enter valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }
}