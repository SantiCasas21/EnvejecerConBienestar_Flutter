import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/juegos/data/models/actividad_cognitiva_model.dart';
import 'package:envejecer_con_bienestar/features/juegos/domain/models/minijuego_definicion.dart';
import 'package:envejecer_con_bienestar/features/juegos/domain/registry/minijuegos_registry.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/providers/juegos_provider.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/screens/juegos_screen.dart';
import 'package:envejecer_con_bienestar/features/juegos/presentation/widgets/boton_volver_juegos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Pruebas Unitarias de MinijuegosRegistry', () {
    test('Verifica que existan exactamente los 5 minijuegos cognitivos del catálogo', () {
      final catalogo = MinijuegosRegistry.todos;
      expect(catalogo.length, equals(5));

      final ids = catalogo.map((j) => j.id).toList();
      expect(ids, containsAll(['sudoku', 'buscar_pares', 'sopa_letras', 'trivia', 'secuencia_luces']));
    });

    test('Verifica dominios cognitivos y puntuaciones por nivel de dificultad', () {
      // 1. Sudoku
      expect(MinijuegosRegistry.sudoku.titulo, equals('Sudoku'));
      expect(MinijuegosRegistry.sudoku.habilidadCognitiva, equals('Razonamiento y Lógica'));
      expect(MinijuegosRegistry.sudoku.puntosParaNivel(NivelDificultad.basico), equals(120));
      expect(MinijuegosRegistry.sudoku.puntosParaNivel(NivelDificultad.intermedio), equals(280));
      expect(MinijuegosRegistry.sudoku.puntosParaNivel(NivelDificultad.avanzado), equals(500));

      // 2. Buscar Pares
      expect(MinijuegosRegistry.buscarPares.titulo, equals('Buscar Pares'));
      expect(MinijuegosRegistry.buscarPares.habilidadCognitiva, equals('Memoria de Trabajo'));
      expect(MinijuegosRegistry.buscarPares.puntosParaNivel(NivelDificultad.basico), equals(120));
      expect(MinijuegosRegistry.buscarPares.puntosParaNivel(NivelDificultad.intermedio), equals(250));
      expect(MinijuegosRegistry.buscarPares.puntosParaNivel(NivelDificultad.avanzado), equals(400));

      // 3. Sopa de Letras
      expect(MinijuegosRegistry.sopaLetras.titulo, equals('Sopa de Letras'));
      expect(MinijuegosRegistry.sopaLetras.habilidadCognitiva, equals('Atención y Lenguaje'));
      expect(MinijuegosRegistry.sopaLetras.puntosParaNivel(NivelDificultad.basico), equals(120));
      expect(MinijuegosRegistry.sopaLetras.puntosParaNivel(NivelDificultad.intermedio), equals(250));
      expect(MinijuegosRegistry.sopaLetras.puntosParaNivel(NivelDificultad.avanzado), equals(450));

      // 4. Trivia de Cultura General
      expect(MinijuegosRegistry.trivia.titulo, equals('Trivia de Cultura General'));
      expect(MinijuegosRegistry.trivia.habilidadCognitiva, equals('Memoria Semántica'));
      expect(MinijuegosRegistry.trivia.puntosParaNivel(NivelDificultad.basico), equals(150));
      expect(MinijuegosRegistry.trivia.puntosParaNivel(NivelDificultad.intermedio), equals(250));
      expect(MinijuegosRegistry.trivia.puntosParaNivel(NivelDificultad.avanzado), equals(300));

      // 5. Secuencia de Luces
      expect(MinijuegosRegistry.secuenciaLuces.titulo, equals('Secuencia de Luces'));
      expect(MinijuegosRegistry.secuenciaLuces.habilidadCognitiva, equals('Memoria de Trabajo y Reflejos'));
      expect(MinijuegosRegistry.secuenciaLuces.puntosParaNivel(NivelDificultad.basico), equals(100));
      expect(MinijuegosRegistry.secuenciaLuces.puntosParaNivel(NivelDificultad.intermedio), equals(250));
      expect(MinijuegosRegistry.secuenciaLuces.puntosParaNivel(NivelDificultad.avanzado), equals(450));
    });
  });

  group('2. Pruebas de Serialización de Modelos de Juegos y Podio', () {
    test('PuntosPorJuegoModel deserializa correctamente JSON del backend', () {
      final json = {
        'juego_id': 'sopa_letras',
        'tipo_juego': 'Sopa de Letras',
        'total_puntos': 750,
        'partidas_jugadas': 5,
        'record_maximo': 250,
        'es_mas_jugado': true,
        'posicion': 1,
        'medalla': '🥇',
      };

      final item = PuntosPorJuegoModel.fromJson(json);

      expect(item.juegoId, equals('sopa_letras'));
      expect(item.tipoJuego, equals('Sopa de Letras'));
      expect(item.totalPuntos, equals(750));
      expect(item.partidasJugadas, equals(5));
      expect(item.recordMaximo, equals(250));
      expect(item.esMasJugado, isTrue);
      expect(item.posicion, equals(1));
      expect(item.medalla, equals('🥇'));
    });

    test('PodioFamiliarItemModel deserializa correctamente JSON del backend', () {
      final json = {
        'posicion': 1,
        'usuario_id': 42,
        'nombre': 'Abuela Rosa',
        'rol': 'adulto_mayor',
        'parentesco': 'Titular',
        'puntaje_maximo': 450,
        'total_puntos': 1200,
        'partidas_jugadas': 4,
        'juego_record': 'Sudoku',
        'medalla': '🥇',
        'es_usuario_actual': true,
      };

      final item = PodioFamiliarItemModel.fromJson(json);

      expect(item.posicion, equals(1));
      expect(item.usuarioId, equals(42));
      expect(item.nombre, equals('Abuela Rosa'));
      expect(item.rol, equals('adulto_mayor'));
      expect(item.parentesco, equals('Titular'));
      expect(item.puntajeMaximo, equals(450));
      expect(item.totalPuntos, equals(1200));
      expect(item.partidasJugadas, equals(4));
      expect(item.juegoRecord, equals('Sudoku'));
      expect(item.medalla, equals('🥇'));
      expect(item.esUsuarioActual, isTrue);
    });

    test('PodioFamiliarRespuestaModel deserializa lista y estado de vinculación', () {
      final json = {
        'total_miembros': 2,
        'hay_vinculacion': true,
        'filtro_juego': 'Todos',
        'codigo_vinculacion_usuario': 'ECB-9988',
        'podio': [
          {
            'posicion': 1,
            'usuario_id': 10,
            'nombre': 'Hija Laura',
            'rol': 'cuidador',
            'parentesco': 'Hija',
            'puntaje_maximo': 500,
            'total_puntos': 900,
            'partidas_jugadas': 2,
            'juego_record': 'Sopa de Letras',
            'medalla': '🥇',
            'es_usuario_actual': false,
          },
          {
            'posicion': 2,
            'usuario_id': 20,
            'nombre': 'Abuelo Jaime',
            'rol': 'adulto_mayor',
            'parentesco': 'Titular',
            'puntaje_maximo': 300,
            'total_puntos': 600,
            'partidas_jugadas': 2,
            'juego_record': 'Memoria',
            'medalla': '🥈',
            'es_usuario_actual': true,
          }
        ]
      };

      final resp = PodioFamiliarRespuestaModel.fromJson(json);

      expect(resp.totalMiembros, equals(2));
      expect(resp.hayVinculacion, isTrue);
      expect(resp.filtroJuego, equals('Todos'));
      expect(resp.codigoVinculacionUsuario, equals('ECB-9988'));
      expect(resp.podio.length, equals(2));
      expect(resp.podio[0].nombre, equals('Hija Laura'));
      expect(resp.podio[0].medalla, equals('🥇'));
      expect(resp.podio[1].nombre, equals('Abuelo Jaime'));
      expect(resp.podio[1].medalla, equals('🥈'));

      final vacio = PodioFamiliarRespuestaModel.vacio();
      expect(vacio.totalMiembros, equals(0));
      expect(vacio.hayVinculacion, isFalse);
      expect(vacio.podio, isEmpty);
    });
  });

  group('3. Pruebas de BotonVolverJuegos', () {
    testWidgets('BotonVolverJuegos es visible, tiene texto y touch target accesible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: BotonVolverJuegos(),
            ),
          ),
        ),
      );

      // 1. Texto visible sin doble flecha
      final textoFinder = find.text('Volver a Juegos');
      expect(textoFinder, findsOneWidget);

      // 2. Icono de retroceso
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // 3. Touch target
      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.width, greaterThanOrEqualTo(160));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('4. Pruebas de Widget de JuegosScreen (Catálogo, Mis Récords, Círculo Familiar e Historial)', () {
    testWidgets('JuegosScreen renderiza catálogo, ranking de 5 juegos, filtros familiares y selector de días', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final statsFake = EstadisticasJuegosModel(
        totalPuntos: 1250,
        partidasJugadas: 8,
        recordMaximo: 400,
        juegoFavorito: 'Sudoku',
      );

      final puntosPorJuegoFake = [
        PuntosPorJuegoModel(
          juegoId: 'sudoku',
          tipoJuego: 'Sudoku',
          totalPuntos: 600,
          partidasJugadas: 3,
          recordMaximo: 350,
          esMasJugado: false,
          posicion: 1,
          medalla: '🥇',
        ),
        PuntosPorJuegoModel(
          juegoId: 'sopa_letras',
          tipoJuego: 'Sopa de Letras',
          totalPuntos: 400,
          partidasJugadas: 4,
          recordMaximo: 180,
          esMasJugado: true, // Más jugado
          posicion: 2,
          medalla: '🥈',
        ),
        PuntosPorJuegoModel(
          juegoId: 'buscar_pares',
          tipoJuego: 'Buscar Pares',
          totalPuntos: 150,
          partidasJugadas: 1,
          recordMaximo: 150,
          esMasJugado: false,
          posicion: 3,
          medalla: '🥉',
        ),
        PuntosPorJuegoModel(
          juegoId: 'trivia',
          tipoJuego: 'Trivia de Cultura General',
          totalPuntos: 100,
          partidasJugadas: 1,
          recordMaximo: 100,
          esMasJugado: false,
          posicion: 4,
          medalla: '4º',
        ),
        PuntosPorJuegoModel(
          juegoId: 'ordenar_secuencia',
          tipoJuego: 'Secuencia de Luces',
          totalPuntos: 0,
          partidasJugadas: 0,
          recordMaximo: 0,
          esMasJugado: false,
          posicion: 5,
          medalla: '5º',
        ),
      ];

      final podioFake = PodioFamiliarRespuestaModel(
        totalMiembros: 2,
        hayVinculacion: true,
        filtroJuego: 'Todos',
        codigoVinculacionUsuario: 'ECB-1001',
        podio: [
          PodioFamiliarItemModel(
            posicion: 1,
            usuarioId: 1,
            nombre: 'Don Santiago',
            rol: 'adulto_mayor',
            parentesco: 'Titular',
            puntajeMaximo: 350,
            totalPuntos: 850,
            partidasJugadas: 5,
            juegoRecord: 'Sudoku',
            medalla: '🥇',
            esUsuarioActual: true,
          ),
          PodioFamiliarItemModel(
            posicion: 2,
            usuarioId: 2,
            nombre: 'Carolina Hija',
            rol: 'cuidador',
            parentesco: 'Hija',
            puntajeMaximo: 280,
            totalPuntos: 560,
            partidasJugadas: 2,
            juegoRecord: 'Sopa de Letras',
            medalla: '🥈',
            esUsuarioActual: false,
          ),
        ],
      );

      final historialFake = [
        ActividadCognitiva(
          id: 1,
          usuarioId: 1,
          tipoJuego: 'Sudoku',
          puntaje: 250,
          fechaRealizacion: DateTime.now().subtract(const Duration(hours: 2)),
          nombreJugador: 'Don Santiago',
          esUsuarioActual: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            estadisticasJuegosProvider.overrideWith((ref) async => statsFake),
            puntosPorJuegoProvider.overrideWith((ref) async => puntosPorJuegoFake),
            podioFamiliarProvider.overrideWith((ref, tipoJuego) async => podioFake),
            historialJuegosProvider.overrideWith((ref) async => historialFake),
            historialFiltradoProvider.overrideWith((ref, params) async => historialFake),
            mejoresPuntajesProvider.overrideWith((ref, tipoJuego) async => []),
          ],
          child: const MaterialApp(
            home: JuegosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Título principal y encabezado
      expect(find.text('Juegos y Estimulación'), findsOneWidget);
      expect(find.text('🎮 Gimnasio Mental'), findsOneWidget);

      // 2. Renderizado de minijuegos del catálogo y badges superiores de habilidad cognitiva
      expect(find.text('Sudoku'), findsWidgets);
      expect(find.text('Buscar Pares'), findsWidgets);
      expect(find.text('Sopa de Letras'), findsWidgets);
      expect(find.text('Trivia de Cultura General'), findsWidgets);
      expect(find.text('Secuencia de Luces'), findsWidgets);

      // Badges superiores en catálogo (separados del título y sin desbordamiento)
      expect(find.text('Razonamiento y Lógica'), findsWidgets);
      expect(find.text('Memoria de Trabajo'), findsWidgets);
      expect(find.text('Atención y Lenguaje'), findsWidgets);
      expect(find.text('Memoria Semántica'), findsWidgets);
      expect(find.text('Memoria de Trabajo y Reflejos'), findsWidgets);

      // 3. SECCIÓN MIS RÉCORDS: Verifica los 5 minijuegos ordenados por puntos
      expect(find.text('Mis Récords'), findsOneWidget);
      expect(find.text('600 pts'), findsOneWidget); // 1º Sudoku
      expect(find.text('400 pts'), findsOneWidget); // 2º Sopa de Letras
      expect(find.text('150 pts'), findsOneWidget); // 3º Buscar Pares
      expect(find.text('100 pts'), findsOneWidget); // 4º Trivia
      expect(find.text('0 pts'), findsOneWidget);   // 5º Secuencia

      // Verifica indicador '⭐ El más jugado'
      expect(find.text('⭐ El más jugado'), findsOneWidget);

      // 4. CAMBIAR A PESTAÑA 'CÍRCULO FAMILIAR'
      final circuloFinder = find.text('Círculo Familiar');
      await tester.ensureVisible(circuloFinder);
      expect(circuloFinder, findsOneWidget);
      await tester.tap(circuloFinder);
      await tester.pumpAndSettle();

      // Verifica filtros por minijuego del círculo familiar
      expect(find.widgetWithText(ChoiceChip, 'Todos'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Sudoku'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Buscar Pares'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Sopa de Letras'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Trivia de Cultura General'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Secuencia de Luces'), findsOneWidget);

      // Tocar un chip de filtro por juego
      final sudokuChip = find.widgetWithText(ChoiceChip, 'Sudoku');
      await tester.ensureVisible(sudokuChip);
      await tester.tap(sudokuChip);
      await tester.pumpAndSettle();

      // Verifica miembros del podio familiar y visualización del total acumulado como valor principal
      expect(find.textContaining('Don Santiago'), findsWidgets);
      expect(find.textContaining('Carolina Hija'), findsWidgets);
      expect(find.text('850 pts'), findsWidgets); // Total acumulado Don Santiago
      expect(find.text('560 pts'), findsWidgets); // Total acumulado Carolina Hija
      expect(find.textContaining('Récord: 350 pts'), findsWidgets);
      expect(find.textContaining('Récord: 280 pts'), findsWidgets);

      // 5. SECCIÓN HISTORIAL: Selector temporal de días y modo familiar
      final historialTitle = find.text('📜 Historial de Partidas');
      await tester.ensureVisible(historialTitle);
      expect(historialTitle, findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Solo yo'), findsOneWidget);

      // Opciones de días en historial
      expect(find.widgetWithText(ChoiceChip, 'Todo'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '1 día'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '3 días'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '5 días'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '8 días'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '15 días'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '30 días'), findsOneWidget);

      // Probar selección de '8 días'
      final chip8 = find.widgetWithText(ChoiceChip, '8 días');
      await tester.ensureVisible(chip8);
      await tester.tap(chip8);
      await tester.pumpAndSettle();
    });

    testWidgets('JuegosScreen en pantalla móvil 390x844 renderiza catálogo y podio sin desbordamientos RenderFlex', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final statsFake = EstadisticasJuegosModel(
        totalPuntos: 850,
        partidasJugadas: 5,
        recordMaximo: 350,
        juegoFavorito: 'Sudoku',
      );

      final puntosPorJuegoFake = [
        PuntosPorJuegoModel(
          juegoId: 'sudoku',
          tipoJuego: 'Sudoku',
          totalPuntos: 600,
          partidasJugadas: 3,
          recordMaximo: 350,
          esMasJugado: true,
          posicion: 1,
          medalla: '🥇',
        ),
      ];

      final podioFake = PodioFamiliarRespuestaModel(
        totalMiembros: 2,
        hayVinculacion: true,
        filtroJuego: 'Todos',
        codigoVinculacionUsuario: 'ECB-1001',
        podio: [
          PodioFamiliarItemModel(
            posicion: 1,
            usuarioId: 1,
            nombre: 'Don Santiago',
            rol: 'adulto_mayor',
            parentesco: 'Titular',
            puntajeMaximo: 350,
            totalPuntos: 850,
            partidasJugadas: 5,
            juegoRecord: 'Sudoku',
            medalla: '🥇',
            esUsuarioActual: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            estadisticasJuegosProvider.overrideWith((ref) async => statsFake),
            puntosPorJuegoProvider.overrideWith((ref) async => puntosPorJuegoFake),
            podioFamiliarProvider.overrideWith((ref, tipoJuego) async => podioFake),
            historialJuegosProvider.overrideWith((ref) async => []),
            historialFiltradoProvider.overrideWith((ref, params) async => []),
            mejoresPuntajesProvider.overrideWith((ref, tipoJuego) async => []),
          ],
          child: const MaterialApp(
            home: JuegosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Desplazamiento completo para verificar que todas las tarjetas rendericen sin overflow
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Secuencia de Luces'), 100, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text('Secuencia de Luces'), findsWidgets);
    });
  });
}
