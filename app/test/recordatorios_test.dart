import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/core/utils/notification_service.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/medicamento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/providers/medicamentos_provider.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/alarma_toma_dialog.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/alarmas_horarios_tab.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/medicamento_popup_dialog.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/medicamento_card.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/screens/medicamentos_screen.dart';

import 'package:envejecer_con_bienestar/features/auth/presentation/providers/auth_provider.dart';
import 'package:envejecer_con_bienestar/features/auth/data/models/usuario_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/providers/tratamientos_provider.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/tratamiento_model.dart';

class FakeMedicamentosNotifier extends MedicamentosNotifier {
  final List<Medicamento> initialList;
  bool toggleTomadoCalled = false;
  dynamic toggledId;

  FakeMedicamentosNotifier(this.initialList);

  @override
  Future<List<Medicamento>> build() async => initialList;

  @override
  Future<void> toggleTomado(dynamic id) async {
    toggleTomadoCalled = true;
    toggledId = id;
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id.toString() == id.toString() ? m.copyWith(estaTomado: true) : m).toList(),
    );
  }
}

class FakeAuthNotifier extends AuthNotifier {
  final UsuarioModel? user;
  FakeAuthNotifier({this.user});

  @override
  AuthState build() => AuthState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      );
}

class FakeTratamientosNotifier extends TratamientosNotifier {
  @override
  Future<List<TratamientoModel>> build() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> methodCalls = [];
  const MethodChannel channel = MethodChannel('dexterous.com/flutter/local_notifications');

  setUpAll(() {
    NotificationService.isTestMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      methodCalls.add(methodCall);
      if (methodCall.method == 'initialize') {
        return true;
      }
      return null;
    });
  });

  setUp(() {
    methodCalls.clear();
  });

  const med1 = Medicamento(
    id: 1,
    nombre: 'Losartán Potásico',
    miligramos: '50',
    notas: 'Tomar con medio vaso de agua',
    frecuencia: 12,
    horaAlarma: '08:00',
    cantidadRestante: 25,
    estaTomado: false,
    icono: '💊',
    colorIcono: '#0D9488',
  );

  const med2 = Medicamento(
    id: 2,
    nombre: 'Metformina',
    miligramos: '850',
    notas: 'Tomar durante el almuerzo',
    frecuencia: 24,
    horaAlarma: '13:00',
    cantidadRestante: 15,
    estaTomado: true,
    icono: '💊',
    colorIcono: '#64748B',
  );

  group('1. Pruebas Unitarias de Lógica y Servicio (NotificationService)', () {
    test('Inicialización del servicio NotificationService.init()', () async {
      await expectLater(NotificationService.init(), completes);
    });

    test('Programación de recordatorio diario NotificationService.programarRecordatorioMedicamento()', () async {
      await expectLater(NotificationService.programarRecordatorioMedicamento(med1), completes);
    });

    test('Posponer recordatorio por defecto a 10 min NotificationService.posponerRecordatorio()', () async {
      await expectLater(NotificationService.posponerRecordatorio(med1, minutos: 10), completes);
    });

    test('Reprogramar todas las alarmas masivamente NotificationService.reprogramarTodasLasAlarmas()', () async {
      await expectLater(NotificationService.reprogramarTodasLasAlarmas([med1, med2]), completes);
    });

    test('Cancelar notificaciones de medicamento NotificationService.cancelarNotificacion()', () async {
      await expectLater(NotificationService.cancelarNotificacion(med1.id), completes);
    });

    test('Prueba sonora inmediata de alarma NotificationService.probarAlarmaSonora()', () async {
      await expectLater(NotificationService.probarAlarmaSonora(), completes);
    });
  });

  group('2. Pruebas de Widgets y Accesibilidad de AlarmaTomaDialog', () {
    testWidgets('Renderiza título, datos del medicamento y los 3 botones de acción accesibles', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = FakeMedicamentosNotifier([med1]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicamentosNotifierProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AlarmaTomaDialog(
                medicamento: med1,
                horaToma: TimeOfDay(hour: 8, minute: 0),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Título y subtítulo amigables
      expect(find.text('¿Es hora de tu medicina?'), findsOneWidget);
      expect(find.text('Recordatorio prioritario de salud'), findsOneWidget);
      expect(find.text('🔔'), findsOneWidget);

      // 2. Información del medicamento
      expect(find.text('Losartán Potásico'), findsOneWidget);
      expect(find.text('50 mg'), findsOneWidget);
      expect(find.text('Tomar con medio vaso de agua'), findsOneWidget);
      expect(find.text('Quedan 25 pastillas'), findsOneWidget);

      // 3. Presencia de los 3 botones de acción con touch targets accesibles
      final btnTomado = find.text('✓ Ya me la tomé');
      final btnSnooze = find.text('⏰ Recordarme en 10 minutos');
      final btnOmitir = find.text('✕ Omitir por ahora');

      expect(btnTomado, findsOneWidget);
      expect(btnSnooze, findsOneWidget);
      expect(btnOmitir, findsOneWidget);

      // Verificar altura accesible >= 48dp / 56dp
      final btnTomadoSize = tester.getSize(find.ancestor(of: btnTomado, matching: find.byType(SizedBox)).first);
      expect(btnTomadoSize.height, greaterThanOrEqualTo(56.0));

      final btnSnoozeSize = tester.getSize(find.ancestor(of: btnSnooze, matching: find.byType(SizedBox)).first);
      expect(btnSnoozeSize.height, greaterThanOrEqualTo(56.0));
    });

    testWidgets('Interacción: Tocar "✓ Ya me la tomé" ejecuta toggleTomado y muestra SnackBar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = FakeMedicamentosNotifier([med1]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicamentosNotifierProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AlarmaTomaDialog.mostrar(context: context, medicamento: med1),
                  child: const Text('Abrir Diálogo'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir diálogo
      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      expect(find.text('¿Es hora de tu medicina?'), findsOneWidget);

      // Tocar "✓ Ya me la tomé"
      await tester.tap(find.text('✓ Ya me la tomé'));
      await tester.pumpAndSettle();

      // Verificar que se invocó toggleTomado
      expect(fakeNotifier.toggleTomadoCalled, isTrue);
      expect(fakeNotifier.toggledId, equals(1));

      // Verificar SnackBar de felicitación
      expect(find.textContaining('Registraste la toma de Losartán Potásico'), findsOneWidget);
    });

    testWidgets('Interacción: Tocar "⏰ Recordarme en 10 minutos" pospone la alarma y cierra diálogo', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = FakeMedicamentosNotifier([med1]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicamentosNotifierProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AlarmaTomaDialog.mostrar(context: context, medicamento: med1),
                  child: const Text('Abrir Diálogo'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir diálogo
      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      // Tocar "⏰ Recordarme en 10 minutos"
      await tester.tap(find.text('⏰ Recordarme en 10 minutos'));
      await tester.pumpAndSettle();

      // Verificar SnackBar de confirmación de posponer
      expect(find.textContaining('Te volveremos a recordar Losartán Potásico en 10 minutos'), findsOneWidget);
    });
  });

  group('3. Pruebas de Widgets y Cronograma de AlarmasHorariosTab', () {
    testWidgets('Renderiza banner de confianza, botones Probar Alarma / Sincronizar y cronograma ordenado', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlarmasHorariosTab(
              medicamentos: [med1, med2],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Banner informativo de confianza
      expect(find.text('Alarmas Sincronizadas y Activas'), findsOneWidget);
      expect(
        find.text('Tus recordatorios están programados para avisarte puntualmente por sonido y vibración.'),
        findsOneWidget,
      );

      // 2. Botones de acción principales
      final btnProbar = find.widgetWithText(ElevatedButton, 'Probar Alarma');
      final btnSincronizar = find.widgetWithText(OutlinedButton, 'Sincronizar');

      expect(btnProbar, findsOneWidget);
      expect(btnSincronizar, findsOneWidget);

      // Probar interacción de "Probar Alarma"
      await tester.tap(btnProbar);
      await tester.pumpAndSettle();
      expect(find.textContaining('¡Prueba emitida!'), findsOneWidget);

      // Descartar SnackBar antes de abrir el siguiente
      ScaffoldMessenger.of(tester.element(btnSincronizar)).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Probar interacción de "Sincronizar"
      await tester.tap(btnSincronizar);
      await tester.pumpAndSettle();
      expect(find.textContaining('Se sincronizaron y programaron las alarmas'), findsOneWidget);

      // 3. Encabezado de cronograma y conteo
      expect(find.text('Cronograma de Tomas de Hoy'), findsOneWidget);
      // med1 (freq 12h = 2 tomas: 08:00 y 20:00) + med2 (freq 24h = 1 toma: 13:00) = 3 tomas
      expect(find.text('3 tomas'), findsOneWidget);

      // 4. Detalle de los medicamentos y badges en el cronograma
      expect(find.text('Losartán Potásico'), findsWidgets);
      expect(find.text('Metformina'), findsWidgets);
      expect(find.text('Tomada ✓'), findsOneWidget); // med2 está tomado
      expect(find.text('Simular'), findsWidgets);
    });

    testWidgets('Renderiza estado vacío cuando no hay medicamentos registrados', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlarmasHorariosTab(
              medicamentos: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No hay tomas registradas'), findsOneWidget);
      expect(find.text('0 tomas'), findsOneWidget);
    });

    testWidgets('Verificación en pantalla móvil 390x844 sin desbordamientos RenderFlex', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlarmasHorariosTab(
              medicamentos: [med1, med2],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll completo para garantizar que no ocurra ningún desbordamiento
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Simular').last, 100, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text('Cronograma de Tomas de Hoy'), findsOneWidget);
    });
  });

  group('4. Pruebas de Personalización en MedicamentoPopupDialog y MedicamentoCard', () {
    testWidgets('MedicamentoPopupDialog muestra detalle de alarmas, vista previa personalizada y botón de alarma activa', (tester) async {
      tester.view.physicalSize = const Size(420, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = FakeMedicamentosNotifier([med1]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicamentosNotifierProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MedicamentoPopupDialog(medicamento: med1),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar título de alarmas y desglose de tomas
      expect(find.text('Alarmas y Horario del Día'), findsOneWidget);
      expect(find.text('2 tomas/día'), findsOneWidget);
      expect(find.text('Toma 1 del día'), findsOneWidget);
      expect(find.text('Toma 2 del día'), findsOneWidget);

      // Verificar aviso personalizado
      expect(find.text('Aviso personalizado en tu teléfono:'), findsOneWidget);
      expect(find.textContaining('Hora de tu medicina: Losartán Potásico'), findsOneWidget);

      // Verificar botón de alarma activa y acciones de sonido y sincronización
      expect(find.text('Ver Pantalla de Alarma Activa'), findsOneWidget);
      expect(find.text('Probar Sonido'), findsOneWidget);
      expect(find.text('Sincronizar'), findsOneWidget);

      // Tocar "Probar Sonido"
      await tester.tap(find.text('Probar Sonido'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Probando sonido de alarma para Losartán Potásico'), findsOneWidget);
    });

    testWidgets('MedicamentoCard muestra banda de alarmas y botón de prueba sonora', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: MedicamentoCard(medicamento: med1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Losartán Potásico'), findsOneWidget);
      expect(find.text('Alarma: 08:00 AM'), findsOneWidget);
      expect(find.text('(2 tomas/día)'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('MedicamentosScreen mantiene únicamente 2 pestañas organizadas (Tomas de Hoy y Mi Botiquín)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeNotifier = FakeMedicamentosNotifier([med1]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => FakeAuthNotifier(
              user: const UsuarioModel(id: 1, nombre: 'Santiago', email: 's@test.com', rol: 'adulto_mayor'),
            )),
            medicamentosNotifierProvider.overrideWith(() => fakeNotifier),
            tratamientosNotifierProvider.overrideWith(FakeTratamientosNotifier.new),
          ],
          child: const MaterialApp(
            home: MedicamentosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que existan las 2 pestañas esperadas
      expect(find.text('Tomas de Hoy'), findsOneWidget);
      expect(find.text('Mi Botiquín'), findsOneWidget);
      // Verificar que NO exista la pestaña separada de "Alarmas"
      expect(find.text('Alarmas'), findsNothing);
    });
  });
}
