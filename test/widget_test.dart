import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safe/core/utils/injection.dart' as di;
import 'package:safe/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await di.sl.reset();
    await di.init();
  });

  testWidgets('SAFE app opens the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeApp());
    await tester.pumpAndSettle();

    expect(find.text('Mulai Sekarang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
