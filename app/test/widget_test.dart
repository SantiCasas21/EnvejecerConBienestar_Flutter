import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EnvejecerConBienestarApp(),
      ),
    );
    expect(find.byType(EnvejecerConBienestarApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
