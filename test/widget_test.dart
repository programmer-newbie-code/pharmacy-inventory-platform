// fix ci: `flutter create --platforms=... .` (CI's platform-folder backfill step)
// writes this file with a default `MyApp` smoke test if it's absent — but this repo
// has no `MyApp` class, so that default fails analysis. Committing our own trivial
// version here means `flutter create` sees the file already exists and leaves it
// alone. Real widget tests live under test/features/.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder - see test/features/ for real widget tests', () {
    expect(true, isTrue);
  });
}
