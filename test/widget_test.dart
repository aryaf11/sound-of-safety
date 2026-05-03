import 'package:flutter_test/flutter_test.dart';

import 'package:sound_of_safety/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boot surface', (tester) async {
    await tester.pumpWidget(const SoundOfSafetyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
