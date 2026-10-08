import 'package:flutter/services.dart';

class WeightInputFormatter extends TextInputFormatter {
  static final _validWeight = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _validWeight.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
