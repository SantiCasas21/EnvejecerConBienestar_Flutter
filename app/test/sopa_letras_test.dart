import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/screens/sopa_letras_screen.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/widgets/boton_volver_juegos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Widgets e Interacción de SopaLetrasScreen', () {
    testWidgets('Renderiza título, BotonVolverJuegos y verifica visibilidad', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SopaLetrasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Título de la pantalla
      expect(find.text('🔤 Sopa de Letras'), findsOneWidget);

      // 2. Botón de retroceso BotonVolverJuegos visible
      final botonVolver = find.byType(BotonVolverJuegos);
      expect(botonVolver, findsOneWidget);
      expect(find.text('Volver a Juegos'), findsOneWidget);

      // 3. Accesibilidad táctil del botón de retroceso (>= 160x44)
      final backSize = tester.getSize(botonVolver);
      expect(backSize.height, greaterThanOrEqualTo(44.0));
      expect(backSize.width, greaterThanOrEqualTo(160.0));
    });

    testWidgets('Checklist de palabras es visible e informativo (no auto-resuelve al pulsar)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SopaLetrasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Palabras del nivel intermedio 8x8 por defecto
      expect(find.text('AGUA'), findsWidgets);
      expect(find.text('SALUD'), findsWidgets);
      expect(find.text('VIDA'), findsWidgets);
      expect(find.text('PASO'), findsWidgets);
      expect(find.text('AMOR'), findsWidgets);

      // Estado inicial: 0 / 5 halladas
      expect(find.text('0 / 5 halladas'), findsOneWidget);

      // Tocar el texto de la palabra en la lista
      await tester.tap(find.text('AGUA').first);
      await tester.pumpAndSettle();

      // VERIFICACIÓN CRÍTICA: La palabra NO se resuelve automáticamente
      expect(find.text('0 / 5 halladas'), findsOneWidget);
    });

    testWidgets('Interacción Two-Tap: Tocar celda inicio y celda fin descubre la palabra en el tablero', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SopaLetrasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // En el grid 8x8, 'AGUA' está en la fila 0, columnas 0 a 3 (índices 0, 1, 2, 3 en el GridView)
      final gridCells = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );

      expect(gridCells, findsNWidgets(64)); // 8x8 = 64 celdas

      // 1. Toque 1: Celda inicial [0, 0] (letra 'A')
      await tester.tap(gridCells.at(0));
      await tester.pump();

      // 2. Toque 2: Celda final [0, 3] (letra 'A' de AGUA)
      await tester.tap(gridCells.at(3));
      await tester.pumpAndSettle();

      // Debe mostrar el aviso de éxito
      expect(find.textContaining('¡Encontraste:'), findsOneWidget);

      // El contador debe incrementar a 1 / 5 halladas
      expect(find.text('1 / 5 halladas'), findsOneWidget);

      // Verificar que el checklist tacha la palabra
      final textoAgua = tester.widget<Text>(find.descendant(
        of: find.byType(Wrap),
        matching: find.text('AGUA'),
      ).first);
      expect(textoAgua.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgets('Interacción de Arrastre Gestual (Drag): Deslizar sobre la cuadrícula detecta la palabra', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SopaLetrasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridCells = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );

      // En la fila 0, celda 0 ('A') a celda 3 ('A') forman 'AGUA'.
      final firstCellCenter = tester.getCenter(gridCells.at(0));
      final lastCellCenter = tester.getCenter(gridCells.at(3));

      final gesture = await tester.startGesture(firstCellCenter);
      for (double t = 0.1; t <= 1.0; t += 0.1) {
        await gesture.moveTo(Offset.lerp(firstCellCenter, lastCellCenter, t)!);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // La palabra AGUA debe haber sido encontrada mediante el gesto de arrastre
      expect(find.text('1 / 5 halladas'), findsOneWidget);
      expect(find.textContaining('¡Encontraste:'), findsOneWidget);
    });

    testWidgets('Cambio de niveles de dificultad reconfigura tamaño de cuadrícula y checklist', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SopaLetrasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Nivel por defecto: 8x8 (64 celdas, 5 palabras)
      expect(find.text('8x8 Intermedio (5 pal.)'), findsOneWidget);
      expect(find.text('0 / 5 halladas'), findsOneWidget);

      // 2. Cambiar a 6x6 Básico (36 celdas, 3 palabras: SOL, PAZ, VIDA)
      await tester.tap(find.text('6x6 Básico (3 pal.)'));
      await tester.pumpAndSettle();

      expect(find.text('0 / 3 halladas'), findsOneWidget);
      expect(find.text('SOL'), findsWidgets);
      expect(find.text('PAZ'), findsWidgets);
      expect(find.text('VIDA'), findsWidgets);

      final gridCells6x6 = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(gridCells6x6, findsNWidgets(36)); // 6x6 = 36 celdas

      // 3. Cambiar a 10x10 Avanzado (100 celdas, 6 palabras)
      await tester.tap(find.text('10x10 Avanzado (6 pal.)'));
      await tester.pumpAndSettle();

      expect(find.text('0 / 6 halladas'), findsOneWidget);
      expect(find.text('CAMINAR'), findsWidgets);
      expect(find.text('MEMORIA'), findsWidgets);

      final gridCells10x10 = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(gridCells10x10, findsNWidgets(100)); // 10x10 = 100 celdas
    });
  });
}
