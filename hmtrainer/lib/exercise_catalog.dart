import 'dart:convert';

class ExerciseEntry {
  const ExerciseEntry({
    required this.id,
    required this.name,
    required this.image,
    required this.attribution,
    required this.category,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.koreanInstructions,
  });

  final String id;
  final String name;
  final String image;
  final String attribution;
  final String category;
  final String bodyPart;
  final String equipment;
  final String target;
  final String koreanInstructions;

  String get imageAssetPath => 'data/$image';
}

class ExerciseCatalog {
  ExerciseCatalog._(List<ExerciseEntry> entries)
    : entries = List.unmodifiable(entries),
      strengthExercises = List.unmodifiable(
        _uniqueByName(
          entries.where((exercise) => exercise.category != 'cardio'),
        ),
      ),
      cardioExercises = List.unmodifiable(
        _uniqueByName(
          entries.where(
            (exercise) =>
                exercise.category == 'cardio' ||
                _cardioEquipment.contains(exercise.equipment),
          ),
        ),
      );

  factory ExerciseCatalog.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Exercise data must be a JSON array.');
    }

    return ExerciseCatalog._(
      decoded.map((value) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Each exercise must be a JSON object.');
        }
        final instructions = value['instructions'];
        if (instructions is! Map<String, dynamic>) {
          throw const FormatException(
            'Each exercise must include translated instructions.',
          );
        }

        return ExerciseEntry(
          id: _requiredString(value, 'id'),
          name: _requiredString(value, 'name'),
          image: _requiredImagePath(value),
          attribution: _requiredString(value, 'attribution'),
          category: _requiredString(value, 'category'),
          bodyPart: _requiredString(value, 'body_part'),
          equipment: _requiredString(value, 'equipment'),
          target: _requiredString(value, 'target'),
          koreanInstructions: _requiredString(instructions, 'ko'),
        );
      }).toList(),
    );
  }

  static const _cardioEquipment = {
    'elliptical machine',
    'skierg machine',
    'stationary bike',
    'stepmill machine',
    'upper body ergometer',
  };

  final List<ExerciseEntry> entries;
  final List<ExerciseEntry> strengthExercises;
  final List<ExerciseEntry> cardioExercises;

  static String _requiredString(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Exercise field "$key" must be a non-empty string.',
      );
    }
    return value;
  }

  static String _requiredImagePath(Map<String, dynamic> object) {
    final image = _requiredString(object, 'image');
    if (!image.startsWith('images/') ||
        image.contains('..') ||
        !image.toLowerCase().endsWith('.jpg')) {
      throw const FormatException('Exercise image path is invalid.');
    }
    return image;
  }

  static List<ExerciseEntry> _uniqueByName(Iterable<ExerciseEntry> exercises) {
    final seenNames = <String>{};
    return exercises.where((exercise) {
      return seenNames.add(exercise.name.toLowerCase());
    }).toList();
  }
}
