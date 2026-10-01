import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmtrainer/exercise_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads exercise names and metadata from the bundled dataset', () async {
    final source = await rootBundle.loadString('data/exercises.json');
    final catalog = ExerciseCatalog.fromJson(source);

    expect(catalog.entries, hasLength(1324));
    expect(
      catalog.strengthExercises.any(
        (exercise) => exercise.name == 'barbell bench press',
      ),
      isTrue,
    );
    expect(
      catalog.cardioExercises.any((exercise) => exercise.category == 'cardio'),
      isTrue,
    );
    expect(catalog.entries.first.koreanInstructions, isNotEmpty);
    expect(
      catalog.entries.first.attribution,
      '© Gym visual — https://gymvisual.com/',
    );
    final image = await rootBundle.load(catalog.entries.first.imageAssetPath);
    expect(image.lengthInBytes, greaterThan(0));
  });

  test('rejects malformed exercise data rather than silently dropping it', () {
    expect(
      () => ExerciseCatalog.fromJson('{"name":"not an array"}'),
      throwsFormatException,
    );
    expect(
      () => ExerciseCatalog.fromJson('[{"id":"1"}]'),
      throwsFormatException,
    );
  });
}
