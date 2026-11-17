import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/asistente/data/models/mensaje_ia_model.dart';
import 'package:envejecer_con_bienestar/features/asistente/data/repositories/asistente_repository.dart';
import 'package:envejecer_con_bienestar/features/asistente/presentation/screens/asistente_screen.dart';

class FakeAsistenteRepository implements AsistenteRepository {
  List<MensajeIaModel> historial;
  bool confirmado = false;

  FakeAsistenteRepository({this.historial = const []});

  @override
  Future<List<MensajeIaModel>> getHistorial({int? pacienteId}) async {
    return historial;
  }

  @override
  Future<ChatRespuestaResult> enviarMensaje(
    String mensaje, {
    int? pacienteId,
  }) async {
    return ChatRespuestaResult(
      mensajeUsuario: MensajeIaModel(
        id: 101,
        rol: 'user',
        contenido: mensaje,
      ),
      respuestaAsistente: const MensajeIaModel(
        id: 102,
        rol: 'assistant',
        contenido: 'Revisé tu expediente: no debes tomar Ibuprofeno por tu alergia a los AINEs.',
        alertaPreventiva:
            '⚠️ Precaución por alergia: Ibuprofeno pertenece al grupo AINE.',
      ),
      entidadesActualizadas: const [],
    );
  }

  @override
  Future<ConfirmacionAccionResult> confirmarAccion({
    required int mensajeId,
    required bool aceptar,
    int? pacienteId,
  }) async {
    confirmado = aceptar;
    return ConfirmacionAccionResult(
      mensajeEstado: 'Guardado',
      mensajeActualizado: MensajeIaModel(
        id: mensajeId,
        rol: 'assistant',
        contenido: 'Listo, preparé el registro.',
        accionPendiente: AccionPendienteModel(
          tipo: 'crear_medicamento',
          resumen: 'Guardar Vitamina D3 1000 UI',
          datos: const {'nombre': 'Vitamina D3'},
          estado: aceptar ? 'confirmada' : 'cancelada',
        ),
      ),
      entidadesActualizadas: const ['medicamentos'],
    );
  }

  @override
  Future<void> limpiarHistorial({int? pacienteId}) async {
    historial = [];
  }
}

void main() {
  testWidgets('AsistenteScreen muestra bienvenida y sugerencias sin overflow en 360x700',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeAsistenteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asistenteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: AsistenteScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asistente de Salud IA'), findsOneWidget);
    expect(find.text('¡Hola! Soy Bienestar IA'), findsOneWidget);
    expect(find.text('💊 ¿Qué medicinas me faltan hoy?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AsistenteScreen envía mensaje y muestra alerta preventiva ámbar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeAsistenteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asistenteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: AsistenteScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '¿Puedo tomar Ibuprofeno?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('¿Puedo tomar Ibuprofeno?'), findsOneWidget);
    expect(find.text('Aviso Preventivo de Seguridad'), findsOneWidget);
    expect(
      find.textContaining('Ibuprofeno pertenece al grupo AINE'),
      findsOneWidget,
    );
  });

  testWidgets('AsistenteScreen permite confirmar acción pendiente con 1 toque',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeAsistenteRepository(
      historial: const [
        MensajeIaModel(
          id: 50,
          rol: 'assistant',
          contenido: '¿Confirmas guardar esta vitamina?',
          accionPendiente: AccionPendienteModel(
            tipo: 'crear_medicamento',
            resumen: 'Guardar Vitamina D3 1000 UI',
            datos: {'nombre': 'Vitamina D3'},
            estado: 'pendiente',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asistenteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: AsistenteScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guardar Vitamina D3 1000 UI'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(fakeRepo.confirmado, isTrue);
    expect(
      find.text('Guardado correctamente en tu expediente'),
      findsOneWidget,
    );
  });
}
