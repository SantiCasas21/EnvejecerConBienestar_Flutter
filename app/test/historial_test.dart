import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:envejecer_con_bienestar/features/historial/data/models/historial_toma_model.dart';
import 'package:envejecer_con_bienestar/features/historial/data/models/resumen_adherencia_model.dart';
import 'package:envejecer_con_bienestar/features/historial/data/repositories/historial_repository.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/screens/historial_screen.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/selector_fecha_carousel.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/tarjeta_adherencia_diaria.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/tarjeta_toma_historial.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/seccion_habitos_dia.dart';
import 'package:envejecer_con_bienestar/core/utils/whatsapp_report_service.dart';
import 'package:envejecer_con_bienestar/features/historial/data/models/racha_model.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/adherencia_donut_widget.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/grafica_barras_semanales_widget.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/preview_reporte_dialog.dart';
import 'package:envejecer_con_bienestar/features/historial/presentation/widgets/vista_graficas_reporte.dart';

/// Fake repository para aislar pruebas de llamadas HTTP
class FakeHistorialRepository implements HistorialRepository {
  final List<HistorialTomaModel> tomas;
  final ResumenAdherenciaModel? resumen;
  final List<HabitoHistorialModel> habitos;

  FakeHistorialRepository({
    this.tomas = const [],
    this.resumen,
    this.habitos = const [],
  });

  @override
  Future<List<HistorialTomaModel>> getTomas({
    DateTime? desde,
    DateTime? hasta,
    int? medicamentoId,
    int? pacienteId,
  }) async {
    return tomas;
  }

  @override
  Future<HistorialTomaModel?> registrarToma({
    required int medicamentoId,
    DateTime? fecha,
    String? horaProgramada,
    String estado = 'tomada',
    String? notas,
    int? pacienteId,
  }) async {
    return HistorialTomaModel(
      id: 999,
      usuarioId: pacienteId ?? 1,
      medicamentoId: medicamentoId,
      fecha: '2026-10-28',
      horaProgramada: horaProgramada ?? '08:00',
      estado: estado,
      notas: notas,
    );
  }

  @override
  Future<ResumenAdherenciaModel> getResumenAdherencia({
    DateTime? desde,
    DateTime? hasta,
    int? dias,
    int? pacienteId,
  }) async {
    return resumen ??
        const ResumenAdherenciaModel(
          usuarioId: 1,
          fechaInicio: '2026-10-22',
          fechaFin: '2026-10-28',
          totalEsperadas: 14,
          totalTomadas: 12,
          totalPospuestas: 1,
          totalOmitidas: 1,
          porcentajeAdherenciaGlobal: 85.7,
        );
  }

  @override
  Future<List<HabitoHistorialModel>> getHistorialHabitos({
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    int? pacienteId,
  }) async {
    return habitos;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('1. Pruebas Unitarias de Modelos y Serialización JSON', () {
    test('HistorialTomaModel - fromJson, toJson y getters de estado', () {
      final json = {
        'id': 10,
        'usuario_id': 2,
        'medicamento_id': 5,
        'medicamento_nombre': 'Losartán Potásico',
        'medicamento_icono': '💊',
        'medicamento_miligramos': '50mg',
        'medicamento_color': '#0D9488',
        'fecha': '2026-10-28',
        'hora_programada': '08:00',
        'hora_real': '2026-10-28T08:05:00Z',
        'estado': 'tomada',
        'notas': 'Tomado con agua',
        'created_at': '2026-10-28T08:05:00Z',
      };

      final model = HistorialTomaModel.fromJson(json);

      expect(model.id, equals(10));
      expect(model.usuarioId, equals(2));
      expect(model.medicamentoId, equals(5));
      expect(model.medicamentoNombre, equals('Losartán Potásico'));
      expect(model.medicamentoIcono, equals('💊'));
      expect(model.medicamentoMiligramos, equals('50mg'));
      expect(model.medicamentoColor, equals('#0D9488'));
      expect(model.fecha, equals('2026-10-28'));
      expect(model.horaProgramada, equals('08:00'));
      expect(model.horaReal, equals('2026-10-28T08:05:00Z'));
      expect(model.estado, equals('tomada'));
      expect(model.notas, equals('Tomado con agua'));

      // Getters
      expect(model.fueTomada, isTrue);
      expect(model.fuePospuesta, isFalse);
      expect(model.fueOmitida, isFalse);

      // Simetría toJson
      final exported = model.toJson();
      expect(exported['id'], equals(10));
      expect(exported['medicamento_nombre'], equals('Losartán Potásico'));
      expect(exported['estado'], equals('tomada'));

      // Test de estados alternos y copyWith
      final pospuesta = model.copyWith(estado: 'pospuesta', notas: '10 min tarde');
      expect(pospuesta.fuePospuesta, isTrue);
      expect(pospuesta.fueTomada, isFalse);
      expect(pospuesta.notas, equals('10 min tarde'));

      final omitida = model.copyWith(estado: 'omitida');
      expect(omitida.fueOmitida, isTrue);
      expect(omitida.fueTomada, isFalse);
    });

    test('CumplimientoDiarioModel - fromJson y toJson', () {
      final json = {
        'fecha': '2026-10-27',
        'dia_semana': 'Martes',
        'esperadas': 4,
        'tomadas': 4,
        'pospuestas': 0,
        'omitidas': 0,
        'porcentaje': 100.0,
      };

      final model = CumplimientoDiarioModel.fromJson(json);
      expect(model.fecha, equals('2026-10-27'));
      expect(model.diaSemana, equals('Martes'));
      expect(model.esperadas, equals(4));
      expect(model.tomadas, equals(4));
      expect(model.porcentaje, equals(100.0));

      final exported = model.toJson();
      expect(exported['fecha'], equals('2026-10-27'));
      expect(exported['porcentaje'], equals(100.0));
    });

    test('MedicamentoAdherenciaModel - fromJson y toJson', () {
      final json = {
        'medicamento_id': 7,
        'nombre': 'Metformina',
        'icono': '💊',
        'miligramos': '850mg',
        'color_icono': '#2563EB',
        'tomadas': 6,
        'esperadas': 7,
        'porcentaje': 85.7,
        'cantidad_restante': 18,
        'nivel_stock': 'normal',
      };

      final model = MedicamentoAdherenciaModel.fromJson(json);
      expect(model.medicamentoId, equals(7));
      expect(model.nombre, equals('Metformina'));
      expect(model.porcentaje, equals(85.7));
      expect(model.cantidadRestante, equals(18));
      expect(model.nivelStock, equals('normal'));

      final exported = model.toJson();
      expect(exported['medicamento_id'], equals(7));
      expect(exported['tomadas'], equals(6));
    });

    test('ResumenAdherenciaModel - fromJson y toJson completo con colecciones', () {
      final json = {
        'usuario_id': 1,
        'fecha_inicio': '2026-10-20',
        'fecha_fin': '2026-10-26',
        'total_esperadas': 21,
        'total_tomadas': 19,
        'total_pospuestas': 1,
        'total_omitidas': 1,
        'porcentaje_adherencia_global': 90.5,
        'cumplimiento_diario': [
          {
            'fecha': '2026-10-26',
            'dia_semana': 'Lunes',
            'esperadas': 3,
            'tomadas': 3,
            'pospuestas': 0,
            'omitidas': 0,
            'porcentaje': 100.0,
          }
        ],
        'medicamentos_adherencia': [
          {
            'medicamento_id': 1,
            'nombre': 'Enalapril',
            'icono': '💊',
            'miligramos': '20mg',
            'color_icono': '#0D9488',
            'tomadas': 7,
            'esperadas': 7,
            'porcentaje': 100.0,
            'cantidad_restante': 25,
            'nivel_stock': 'normal',
          }
        ],
      };

      final resumen = ResumenAdherenciaModel.fromJson(json);
      expect(resumen.usuarioId, equals(1));
      expect(resumen.porcentajeAdherenciaGlobal, equals(90.5));
      expect(resumen.cumplimientoDiario.length, equals(1));
      expect(resumen.medicamentosAdherencia.length, equals(1));
      expect(resumen.cumplimientoDiario.first.diaSemana, equals('Lunes'));

      final exported = resumen.toJson();
      expect(exported['total_tomadas'], equals(19));
      expect((exported['cumplimiento_diario'] as List).length, equals(1));
    });

    test('HabitoHistorialModel - fromJson, toJson y cálculo de cumplido', () {
      final jsonCumplido = {
        'id': 1,
        'tipo': 'Agua',
        'meta': 8,
        'progreso_actual': 8,
        'porcentaje': 100.0,
        'fecha': '2026-10-28',
        'cumplido': true,
      };

      final h1 = HabitoHistorialModel.fromJson(jsonCumplido);
      expect(h1.tipo, equals('Agua'));
      expect(h1.meta, equals(8));
      expect(h1.progresoActual, equals(8));
      expect(h1.cumplido, isTrue);

      final exported = h1.toJson();
      expect(exported['id'], equals(1));
      expect(exported['cumplido'], isTrue);
    });
  });

  group('2. Pruebas de Widgets Accesibles del Historial', () {
    testWidgets('SelectorFechaCarousel - renderiza días y callback de selección', (tester) async {
      DateTime? fechaPulsada;
      final hoy = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectorFechaCarousel(
              selectedDate: hoy,
              cumplimientos: [
                CumplimientoDiarioModel(
                  fecha: '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}',
                  diaSemana: 'Hoy',
                  esperadas: 2,
                  tomadas: 2,
                  pospuestas: 0,
                  omitidas: 0,
                  porcentaje: 100.0,
                )
              ],
              onDateSelected: (fecha) {
                fechaPulsada = fecha;
              },
            ),
          ),
        ),
      );

      // Debe mostrar '⭐ Hoy' para el día actual
      expect(find.text('⭐ Hoy'), findsOneWidget);

      // Debe mostrar '⏪ Ayer'
      expect(find.text('⏪ Ayer'), findsOneWidget);

      // Tap en ayer
      await tester.tap(find.text('⏪ Ayer'));
      await tester.pump();

      expect(fechaPulsada, isNotNull);
      final ayer = hoy.subtract(const Duration(days: 1));
      expect(fechaPulsada!.day, equals(ayer.day));
    });

    testWidgets('TarjetaAdherenciaDiaria - psicología positiva y desglose de badges', (tester) async {
      // 1. Caso de alta adherencia >= 80%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaAdherenciaDiaria(
              porcentaje: 85.0,
              tomadas: 3,
              pospuestas: 1,
              omitidas: 0,
              totalEsperadas: 4,
              fechaFormateada: 'Hoy (28/10/2026)',
            ),
          ),
        ),
      );

      expect(find.textContaining('¡Excelente constancia! 🌟'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('3 Tomadas'), findsOneWidget);
      expect(find.text('1 Pospuestas'), findsOneWidget);
      expect(find.text('0 Omitidas'), findsOneWidget);

      // 2. Caso de adherencia regular >= 50%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaAdherenciaDiaria(
              porcentaje: 60.0,
              tomadas: 3,
              pospuestas: 0,
              omitidas: 2,
              totalEsperadas: 5,
              fechaFormateada: 'Ayer (27/10/2026)',
            ),
          ),
        ),
      );

      expect(find.textContaining('¡Buen avance! ☀️'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);

      // 3. Caso día en proceso < 50%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaAdherenciaDiaria(
              porcentaje: 30.0,
              tomadas: 1,
              pospuestas: 0,
              omitidas: 2,
              totalEsperadas: 3,
              fechaFormateada: '25 de Octubre de 2026',
            ),
          ),
        ),
      );

      expect(find.textContaining('🌱 Día en proceso'), findsOneWidget);
    });

    testWidgets('TarjetaTomaHistorial - renderiza medicamento, horario y estados', (tester) async {
      const tomaTomada = HistorialTomaModel(
        id: 1,
        usuarioId: 1,
        medicamentoId: 2,
        medicamentoNombre: 'Atorvastatina',
        medicamentoMiligramos: '20 mg',
        medicamentoIcono: '💊',
        medicamentoColor: '#0D9488',
        fecha: '2026-10-28',
        horaProgramada: '20:00',
        horaReal: '2026-10-28T20:05:00Z',
        estado: 'tomada',
        notas: 'Sin efectos secundarios',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaTomaHistorial(toma: tomaTomada),
          ),
        ),
      );

      expect(find.text('Atorvastatina'), findsOneWidget);
      expect(find.text('20 mg'), findsOneWidget);
      expect(find.text('Tomada'), findsOneWidget);
      expect(find.text('Sin efectos secundarios'), findsOneWidget);
      expect(find.textContaining('Prog: 20:00'), findsOneWidget);

      // Caso de estado Pospuesta
      const tomaPospuesta = HistorialTomaModel(
        id: 2,
        usuarioId: 1,
        medicamentoId: 3,
        medicamentoNombre: 'Insulina',
        fecha: '2026-10-28',
        horaProgramada: '12:00',
        estado: 'pospuesta',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaTomaHistorial(toma: tomaPospuesta),
          ),
        ),
      );

      expect(find.text('Insulina'), findsOneWidget);
      expect(find.text('Pospuesta (+10 min)'), findsOneWidget);

      // Caso de estado Omitida
      const tomaOmitida = HistorialTomaModel(
        id: 3,
        usuarioId: 1,
        medicamentoId: 4,
        medicamentoNombre: 'Aspirina',
        fecha: '2026-10-28',
        horaProgramada: '15:00',
        estado: 'omitida',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaTomaHistorial(toma: tomaOmitida),
          ),
        ),
      );

      expect(find.text('Aspirina'), findsOneWidget);
      expect(find.text('Omitida'), findsOneWidget);
    });

    testWidgets('SeccionHabitosDia - renderiza hábitos y estado vacío', (tester) async {
      // Estado vacío
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeccionHabitosDia(habitos: []),
          ),
        ),
      );

      expect(find.text('Metas y Hábitos de este Día'), findsOneWidget);
      expect(find.text('No se encontraron hábitos registrados para esta fecha.'), findsOneWidget);

      // Con hábitos
      final habitos = [
        const HabitoHistorialModel(
          id: 1,
          tipo: 'Agua',
          meta: 8,
          progresoActual: 6,
          porcentaje: 75.0,
          fecha: '2026-10-28',
          cumplido: false,
        ),
        const HabitoHistorialModel(
          id: 2,
          tipo: 'Caminata',
          meta: 30,
          progresoActual: 30,
          porcentaje: 100.0,
          fecha: '2026-10-28',
          cumplido: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeccionHabitosDia(habitos: habitos),
          ),
        ),
      );

      expect(find.text('Hidratación'), findsOneWidget);
      expect(find.text('Caminata y Movimiento'), findsOneWidget);
      expect(find.text('6 / 8 vasos (75%)'), findsOneWidget);
      expect(find.text('30 / 30 minutos (100%)'), findsOneWidget);
    });
  });

  group('3. Verificación de HistorialScreen y Cero Desbordamientos (360x700)', () {
    testWidgets('HistorialScreen sin RenderFlex overflow en pantalla compacta 360x700', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorList = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      addTearDown(() {
        FlutterError.onError = oldOnError;
      });
      FlutterError.onError = (details) {
        errorList.add(details);
      };

      final hoy = DateTime.now();
      final hoyStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      final fakeRepo = FakeHistorialRepository(
        tomas: [
          HistorialTomaModel(
            id: 1,
            usuarioId: 1,
            medicamentoId: 10,
            medicamentoNombre: 'Losartán 50mg con descripción larga para verificar que no desborde la pantalla compacta',
            medicamentoMiligramos: '50mg una tableta cada doce horas',
            medicamentoIcono: '💊',
            medicamentoColor: '#0D9488',
            fecha: hoyStr,
            horaProgramada: '08:00',
            horaReal: DateTime.now().toIso8601String(),
            estado: 'tomada',
            notas: 'Nota detallada de toma matutina supervisada por familiar sin complicaciones',
          ),
          HistorialTomaModel(
            id: 2,
            usuarioId: 1,
            medicamentoId: 11,
            medicamentoNombre: 'Metformina 850mg',
            medicamentoMiligramos: '850mg',
            fecha: hoyStr,
            horaProgramada: '20:00',
            estado: 'pospuesta',
          ),
        ],
        resumen: ResumenAdherenciaModel(
          usuarioId: 1,
          fechaInicio: hoyStr,
          fechaFin: hoyStr,
          totalEsperadas: 2,
          totalTomadas: 1,
          totalPospuestas: 1,
          totalOmitidas: 0,
          porcentajeAdherenciaGlobal: 50.0,
          cumplimientoDiario: [
            CumplimientoDiarioModel(
              fecha: hoyStr,
              diaSemana: 'Hoy',
              esperadas: 2,
              tomadas: 1,
              pospuestas: 1,
              omitidas: 0,
              porcentaje: 50.0,
            )
          ],
        ),
        habitos: [
          HabitoHistorialModel(
            id: 1,
            tipo: 'Agua',
            meta: 8,
            progresoActual: 5,
            porcentaje: 62.5,
            fecha: hoyStr,
            cumplido: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historialRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: HistorialScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que la pantalla se renderice sin desbordamientos
      expect(find.byType(HistorialScreen), findsOneWidget);
      expect(find.text('Historial y Hábitos'), findsOneWidget);
      expect(find.byType(SelectorFechaCarousel), findsOneWidget);
      expect(find.byType(TarjetaAdherenciaDiaria), findsOneWidget);
      expect(find.byType(TarjetaTomaHistorial), findsWidgets);
      expect(find.byType(SeccionHabitosDia), findsOneWidget);

      FlutterError.onError = oldOnError;

      // Cero excepciones de desbordamiento (RenderFlex overflow)
      final overflowErrors = errorList.where((e) => e.toString().contains('A RenderFlex overflowed')).toList();
      expect(overflowErrors, isEmpty, reason: 'Se detectaron errores de desbordamiento de pantalla (RenderFlex overflow)');
      expect(errorList, isEmpty, reason: 'Se produjeron errores durante el renderizado');
    });
  });

  group('3. Pruebas Módulo 8: Estadísticas, Gráficas y Reportes de Adherencia', () {
    test('WhatsAppReportService - generación de mensaje estructurado con emojis y métricas', () {
      const resumenTest = ResumenAdherenciaModel(
        usuarioId: 1,
        fechaInicio: '2026-10-22',
        fechaFin: '2026-10-28',
        totalEsperadas: 14,
        totalTomadas: 12,
        totalPospuestas: 1,
        totalOmitidas: 1,
        porcentajeAdherenciaGlobal: 85.7,
        medicamentosAdherencia: [
          MedicamentoAdherenciaModel(
            medicamentoId: 1,
            nombre: 'Losartán Potásico',
            icono: '💊',
            miligramos: '50mg',
            colorIcono: '#0D9488',
            tomadas: 12,
            esperadas: 14,
            porcentaje: 85.7,
            cantidadRestante: 3,
          ),
        ],
        racha: RachaModel(
          usuarioId: 1,
          rachaActual: 5,
          rachaMejor: 10,
          mensajeRacha: '¡5 días seguidos!',
        ),
        resumenHabitos: [
          HabitoResumenModel(
            nombre: 'Tomar agua',
            icono: '💧',
            cumplidos: 6,
            totalDias: 7,
            porcentaje: 85.7,
          ),
        ],
      );

      final mensaje = WhatsAppReportService.construirMensajeReporte(
        nombrePaciente: 'Esperanza Gómez',
        resumen: resumenTest,
        periodoNombre: 'Últimos 7 Días',
      );

      expect(mensaje, contains('🌿 *ENVEJECER CON BIENESTAR*'));
      expect(mensaje, contains('📋 *Reporte de Salud y Cumplimiento*'));
      expect(mensaje, contains('👤 *Paciente:* Esperanza Gómez'));
      expect(mensaje, contains('🗓️ *Periodo:* Últimos 7 Días (2026-10-22 al 2026-10-28)'));
      expect(mensaje, contains('💊 *ADHERENCIA A MEDICAMENTOS:*'));
      expect(mensaje, contains('• Cumplimiento Global: *85.7%*'));
      expect(mensaje, contains('• Tomas Registradas: *12 de 14 esperadas*'));
      expect(mensaje, contains('• Tomas Pospuestas: 1'));
      expect(mensaje, contains('• Tomas Omitidas: 1'));
      expect(mensaje, contains('• 💊 *Losartán Potásico* (50mg): 86% (12/14) ⚠️ _(Quedan 3 pastillas)_'));
      expect(mensaje, contains('🔥 *RACHA DE BIENESTAR:*'));
      expect(mensaje, contains('• *5 días consecutivos* cuidando su salud con constancia.'));
      expect(mensaje, contains('🌱 *HÁBITOS DE VIDA SALUDABLE:*'));
      expect(mensaje, contains('• 💧 *Tomar agua:* 6 de 7 días (86%)'));
      expect(mensaje, contains('✨ _Generado con amor por Envejecer con Bienestar._'));
    });

    testWidgets('PreviewReporteDialog - renderiza vista previa, copia al portapapeles y botones de acción', (tester) async {
      const resumenTest = ResumenAdherenciaModel(
        usuarioId: 1,
        fechaInicio: '2026-10-22',
        fechaFin: '2026-10-28',
        totalEsperadas: 14,
        totalTomadas: 14,
        totalPospuestas: 0,
        totalOmitidas: 0,
        porcentajeAdherenciaGlobal: 100.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PreviewReporteDialog(
              nombrePaciente: 'Esperanza Gómez',
              resumen: resumenTest,
              periodoNombre: 'Últimos 7 Días',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar encabezado y formato amigable
      expect(find.text('Vista Previa del Reporte'), findsOneWidget);
      expect(find.text('Formato amigable para WhatsApp'), findsOneWidget);

      // Verificar burbuja de texto con contenido
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.textContaining('Esperanza Gómez'), findsOneWidget);
      expect(find.textContaining('100.0%'), findsOneWidget);

      // Botón copiar al portapapeles
      final botonCopiar = find.byTooltip('Copiar texto');
      expect(botonCopiar, findsOneWidget);
      await tester.tap(botonCopiar);
      await tester.pump(); // Inicia animación del SnackBar
      expect(find.text('📋 Reporte copiado al portapapeles.'), findsOneWidget);

      // Botones Cerrar y Enviar a WhatsApp
      expect(find.text('Cerrar'), findsOneWidget);
      expect(find.text('Enviar a WhatsApp'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('VistaGraficasReporte - selector 7 vs 30 días, Donut y barras semanales', (tester) async {
      const resumen7Dias = ResumenAdherenciaModel(
        usuarioId: 1,
        fechaInicio: '2026-10-22',
        fechaFin: '2026-10-28',
        totalEsperadas: 14,
        totalTomadas: 12,
        totalPospuestas: 1,
        totalOmitidas: 1,
        porcentajeAdherenciaGlobal: 85.7,
        cumplimientoDiario: [
          CumplimientoDiarioModel(fecha: '2026-10-22', diaSemana: 'Jue', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-23', diaSemana: 'Vie', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-24', diaSemana: 'Sáb', esperadas: 2, tomadas: 1, pospuestas: 1, omitidas: 0, porcentaje: 50.0),
          CumplimientoDiarioModel(fecha: '2026-10-25', diaSemana: 'Dom', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-26', diaSemana: 'Lun', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-27', diaSemana: 'Mar', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-28', diaSemana: 'Mié', esperadas: 2, tomadas: 1, pospuestas: 0, omitidas: 1, porcentaje: 50.0),
        ],
        medicamentosAdherencia: [
          MedicamentoAdherenciaModel(
            medicamentoId: 1,
            nombre: 'Losartán 50mg',
            icono: '💊',
            tomadas: 12,
            esperadas: 14,
            porcentaje: 85.7,
          ),
        ],
        resumenHabitos: [
          HabitoResumenModel(nombre: 'Tomar agua', icono: '💧', cumplidos: 6, totalDias: 7, porcentaje: 85.7),
        ],
        racha: RachaModel(
          usuarioId: 1,
          rachaActual: 5,
          rachaMejor: 10,
          mensajeRacha: '¡5 días seguidos!',
        ),
      );

      final fakeRepo = FakeHistorialRepository(resumen: resumen7Dias);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historialRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VistaGraficasReporte(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Selector de periodos
      expect(find.text('🗓️ Últimos 7 Días'), findsOneWidget);
      expect(find.text('📆 Últimos 30 Días'), findsOneWidget);

      // Donut Widget
      expect(find.byType(AdherenciaDonutWidget), findsOneWidget);
      expect(find.text('85%'), findsWidgets);
      expect(find.text('Adherencia'), findsWidgets);

      // Gráfica de barras semanales
      expect(find.byType(GraficaBarrasSemanalesWidget), findsOneWidget);
      expect(find.text('Cumplimiento por Día'), findsOneWidget);

      // Tarjetas de KPIs (tomas, hábitos, racha)
      expect(find.text('12'), findsOneWidget);
      expect(find.text('de 14 tomas'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('días de racha'), findsOneWidget);

      // Botón de WhatsApp
      expect(find.text('Compartir Resumen por WhatsApp'), findsOneWidget);

      // Tocar selector para cambiar a 30 días
      await tester.tap(find.text('📆 Últimos 30 Días'));
      await tester.pumpAndSettle();
      expect(find.text('📆 Últimos 30 Días'), findsOneWidget);
    });

    testWidgets('Robustez visual Módulo 8: cero RenderFlex overflow en 360x700 con font scale 1.2', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorList = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      addTearDown(() {
        FlutterError.onError = oldOnError;
      });
      FlutterError.onError = (details) {
        errorList.add(details);
      };

      const resumenCompleto = ResumenAdherenciaModel(
        usuarioId: 1,
        fechaInicio: '2026-10-01',
        fechaFin: '2026-10-28',
        totalEsperadas: 28,
        totalTomadas: 26,
        totalPospuestas: 1,
        totalOmitidas: 1,
        porcentajeAdherenciaGlobal: 92.9,
        cumplimientoDiario: [
          CumplimientoDiarioModel(fecha: '2026-10-22', diaSemana: 'Jue', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-23', diaSemana: 'Vie', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-24', diaSemana: 'Sáb', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-25', diaSemana: 'Dom', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-26', diaSemana: 'Lun', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-27', diaSemana: 'Mar', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
          CumplimientoDiarioModel(fecha: '2026-10-28', diaSemana: 'Mié', esperadas: 2, tomadas: 2, pospuestas: 0, omitidas: 0, porcentaje: 100.0),
        ],
        medicamentosAdherencia: [
          MedicamentoAdherenciaModel(
            medicamentoId: 1,
            nombre: 'Losartán Potásico de 50mg con nombre largo para probar desborde',
            icono: '💊',
            miligramos: '50mg',
            tomadas: 26,
            esperadas: 28,
            porcentaje: 92.9,
            cantidadRestante: 4,
          ),
        ],
        resumenHabitos: [
          HabitoResumenModel(nombre: 'Hidratación y 8 vasos de agua diaria', icono: '💧', cumplidos: 25, totalDias: 28, porcentaje: 89.3),
        ],
        racha: RachaModel(
          usuarioId: 1,
          rachaActual: 14,
          rachaMejor: 21,
          mensajeRacha: '¡Dos semanas completas de salud! 🔥',
        ),
      );

      final fakeRepo = FakeHistorialRepository(resumen: resumenCompleto);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historialRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(360, 700),
                textScaler: TextScaler.linear(1.2),
              ),
              child: Scaffold(
                body: VistaGraficasReporte(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VistaGraficasReporte), findsOneWidget);
      expect(find.byType(AdherenciaDonutWidget), findsOneWidget);
      expect(find.byType(GraficaBarrasSemanalesWidget), findsOneWidget);

      // Scroll para recorrer toda la vista
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      FlutterError.onError = oldOnError;

      final overflowErrors = errorList.where((e) => e.toString().contains('A RenderFlex overflowed')).toList();
      expect(overflowErrors, isEmpty, reason: 'Se detectó desbordamiento RenderFlex en pantalla compacta 360x700 con escala 1.2');
      expect(errorList, isEmpty, reason: 'Se produjeron errores durante el renderizado');
    });

    test('WhatsAppReportService - generar reporte diario estructurado', () {
      final tomas = [
        HistorialTomaModel(
          id: 1,
          usuarioId: 3,
          medicamentoId: 1,
          medicamentoNombre: 'Losartán 50mg',
          horaProgramada: '08:00',
          estado: 'tomada',
          fecha: '2026-09-15',
        ),
      ];
      final habitos = [
        const HabitoHistorialModel(
          id: 1,
          tipo: 'agua',
          meta: 2000,
          progresoActual: 2000,
          porcentaje: 100.0,
          fecha: '2026-09-15',
          cumplido: true,
        ),
      ];

      final mensaje = WhatsAppReportService.construirMensajeReporteDiario(
        nombrePaciente: 'Adulto Mayor Demo',
        fechaTexto: '15 de Septiembre de 2026',
        adherencia: 100.0,
        tomas: tomas,
        habitos: habitos,
      );

      expect(mensaje, contains('Reporte Diario de Salud'));
      expect(mensaje, contains('Adulto Mayor Demo'));
      expect(mensaje, contains('15 de Septiembre de 2026'));
      expect(mensaje, contains('Losartán 50mg'));
      expect(mensaje, contains('100% de cumplimiento'));
    });

    testWidgets('HistorialScreen - consulta de fecha sin registros muestra estado vacío con acciones', (tester) async {
      final fakeRepo = FakeHistorialRepository(
        tomas: [],
        habitos: [],
        resumen: const ResumenAdherenciaModel(
          usuarioId: 3,
          fechaInicio: '2026-06-01',
          fechaFin: '2026-06-01',
          totalEsperadas: 0,
          totalTomadas: 0,
          totalPospuestas: 0,
          totalOmitidas: 0,
          porcentajeAdherenciaGlobal: 0.0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historialRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: HistorialScreen(fechaInicial: '2026-06-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin registros en esta fecha'), findsOneWidget);
      expect(find.text('Elegir otra fecha'), findsOneWidget);
      expect(find.text('Volver a Hoy'), findsOneWidget);
    });

    testWidgets('SelectorSemanalWidget - navegación entre semanas con chevrons y 7 días', (tester) async {
      DateTime fechaActual = DateTime(2026, 10, 29); // Jueves 29 Oct 2026
      DateTime? fechaSeleccionada;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectorSemanalWidget(
              selectedDate: fechaActual,
              onDateSelected: (nueva) {
                fechaSeleccionada = nueva;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectorSemanalWidget), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(fechaSeleccionada, isNotNull);
      expect(fechaSeleccionada!.day, equals(22));

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(fechaSeleccionada!.day, equals(5));
    });
  });
}
