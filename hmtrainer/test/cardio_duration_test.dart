import 'package:flutter_test/flutter_test.dart';
import 'package:hmtrainer/cardio_duration.dart';

void main() {
  test('parses three cardio time fields into total seconds', () {
    expect(CardioDuration.tryParseTotalSeconds('1', '2', '3'), 3723);
    expect(CardioDuration.tryParseTotalSeconds('', '', ''), 0);
    expect(CardioDuration.partsFor(3723), ['01', '02', '03']);
  });

  test('accepts configured maximum values and rejects values above them', () {
    expect(CardioDuration.tryParsePart('24', CardioDuration.maxHours), 24);
    expect(CardioDuration.tryParsePart('60', CardioDuration.maxMinutes), 60);
    expect(CardioDuration.tryParsePart('60', CardioDuration.maxSeconds), 60);
    expect(CardioDuration.tryParsePart('25', CardioDuration.maxHours), isNull);
    expect(
      CardioDuration.tryParsePart('61', CardioDuration.maxMinutes),
      isNull,
    );
    expect(
      CardioDuration.tryParsePart('61', CardioDuration.maxSeconds),
      isNull,
    );
    expect(CardioDuration.tryParseTotalSeconds('24', '61', '0'), isNull);
  });
}
