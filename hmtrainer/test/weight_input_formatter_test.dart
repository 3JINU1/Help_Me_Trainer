import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmtrainer/weight_input_formatter.dart';

void main() {
  final formatter = WeightInputFormatter();

  test('accepts integer and decimal weights up to two fractional digits', () {
    const oldValue = TextEditingValue.empty;
    final integer = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(text: '125'),
    );
    final decimal = formatter.formatEditUpdate(
      integer,
      const TextEditingValue(text: '125.5'),
    );
    final twoDecimals = formatter.formatEditUpdate(
      decimal,
      const TextEditingValue(text: '125.55'),
    );

    expect(twoDecimals.text, '125.55');
  });

  test('rejects extra decimal separators and more than two decimal places', () {
    const validValue = TextEditingValue(text: '12.34');

    expect(
      formatter
          .formatEditUpdate(validValue, const TextEditingValue(text: '12.345'))
          .text,
      '12.34',
    );
    expect(
      formatter
          .formatEditUpdate(validValue, const TextEditingValue(text: '12.3.4'))
          .text,
      '12.34',
    );
  });
}
