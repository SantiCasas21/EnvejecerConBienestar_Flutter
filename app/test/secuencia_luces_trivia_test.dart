import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/screens/secuencia_luces_screen.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/screens/trivia_screen.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/widgets/boton_volver_juegos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Widgets de SecuenciaLucesScreen', () {
    testWidgets('Renderiza BotonVolverJuegos, cuadrantes sensoriales y botón Iniciar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SecuenciaLucesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Título y botón volver visible
      expect(find.text('💡 Secuencia Luces'), findsOneWidget);
      expect(find.byType(BotonVolverJuegos), findsOneWidget);
      expect(find.text('Volver a Juegos'), findsOneWidget);

      // 2. Botón para iniciar partida
      expect(find.text('INICIAR'), findsOneWidget);

      // 3. Los 4 cuadrantes sensoriales con sus iconos temáticos
      expect(find.text('🌿'), findsOneWidget); // Verde Esmeralda
      expect(find.text('💧'), findsOneWidget); // Azul Índigo
      expect(find.text('☀️'), findsOneWidget); // Ámbar Cálido
      expect(find.text('❤️'), findsOneWidget); // Coral Rubí
    });
  });

  group('Pruebas de Widgets de TriviaScreen', () {
    testWidgets('Renderiza BotonVolverJuegos, recibidor con las 5 categorías y navegación al cuestionario', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TriviaScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Recibidor: Título en AppBar y botón volver
      expect(find.text('🧠 Trivia de Cultura'), findsOneWidget);
      expect(find.byType(BotonVolverJuegos), findsOneWidget);
      expect(find.text('Volver a Juegos'), findsOneWidget);

      // 2. Banner explicativo del recibidor
      expect(find.text('Elige una Categoría de Trivia'), findsOneWidget);
      expect(find.text('Categorías Disponibles:'), findsOneWidget);

      // 3. Las 5 tarjetas de categorías grandes
      expect(find.text('Deportes'), findsOneWidget);
      expect(find.text('Arte y Cultura'), findsOneWidget);
      expect(find.text('Geografía e Historia'), findsOneWidget);
      expect(find.text('Salud y Bienestar'), findsOneWidget);
      expect(find.text('Ciencia y Naturaleza'), findsOneWidget);

      // Cada tarjeta muestra la meta de preguntas y puntos
      expect(find.text('10 preguntas • Hasta 300 pts'), findsNWidgets(5));

      // 4. Seleccionar una categoría (ej: Deportes) para iniciar la partida
      final deportesCard = find.text('Deportes');
      await tester.ensureVisible(deportesCard);
      await tester.tap(deportesCard);
      await tester.pumpAndSettle();

      // 5. Cuestionario activo de la categoría seleccionada
      expect(find.text('⚽ Deportes'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget); // Botón de regreso al recibidor
      expect(find.textContaining('Pregunta 1 de'), findsOneWidget);
      expect(find.textContaining('💡 Pista'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);

      // 6. Regresar al recibidor de categorías
      final volverCategorias = find.text('Categorías');
      await tester.tap(volverCategorias);
      await tester.pumpAndSettle();

      // Verifica retorno al recibidor
      expect(find.text('Elige una Categoría de Trivia'), findsOneWidget);
      expect(find.text('🧠 Trivia de Cultura'), findsOneWidget);
    });
  });
}
