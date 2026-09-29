import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/screens/sudoku_screen.dart';

void main() {
  testWidgets('SudokuScreen renders properly and allows selecting difficulty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SudokuScreen(),
        ),
      ),
    );

    // Verify title is rendered
    expect(find.text('🔢 Sudoku Senior'), findsOneWidget);

    // Verify initial difficulty chips are visible
    expect(find.text('4x4 Estimulación'), findsOneWidget);
    expect(find.text('6x6 Intermedio'), findsOneWidget);
    expect(find.text('9x9 Clásico'), findsOneWidget);

    // Verify hint button is present
    expect(find.text('💡 Pedir Pista'), findsOneWidget);

    // Switch to 6x6 mode
    await tester.tap(find.text('6x6 Intermedio'));
    await tester.pumpAndSettle();

    // Verify 6 is now present in the keypad
    expect(find.text('6'), findsWidgets);
  });
}
