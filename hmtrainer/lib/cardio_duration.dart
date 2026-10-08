class CardioDuration {
  const CardioDuration._();

  static const maxHours = 24;
  static const maxMinutes = 60;
  static const maxSeconds = 60;

  static List<String> partsFor(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (totalSeconds <= 0) return ['', '', ''];
    return [
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ];
  }

  static int? tryParsePart(String value, int maximum) {
    if (value.isEmpty) return 0;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > maximum) return null;
    return parsed;
  }

  static int? tryParseTotalSeconds(String hours, String minutes, String seconds) {
    final parsedHours = tryParsePart(hours, maxHours);
    final parsedMinutes = tryParsePart(minutes, maxMinutes);
    final parsedSeconds = tryParsePart(seconds, maxSeconds);
    if (parsedHours == null || parsedMinutes == null || parsedSeconds == null) {
      return null;
    }
    return parsedHours * 3600 + parsedMinutes * 60 + parsedSeconds;
  }
}
