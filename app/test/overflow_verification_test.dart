import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:envejecer_con_bienestar/features/auth/presentation/providers/auth_provider.dart';
import 'package:envejecer_con_bienestar/features/auth/data/models/usuario_model.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/providers/perfil_provider.dart';
import 'package:envejecer_con_bienestar/features/perfil/data/models/perfil_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/providers/tratamientos_provider.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/tratamiento_model.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/screens/perfil_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  final UsuarioModel? user;
  FakeAuthNotifier({this.user});

  @override
  AuthState build() => AuthState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      );
}

class FakePerfilNotifier extends PerfilNotifier {
  final PerfilModel? perfil;
  FakePerfilNotifier([this.perfil]);

  @override
  Future<PerfilModel?> build() async => perfil;
}

class FakeTratamientosNotifier extends TratamientosNotifier {
  @override
  Future<List<TratamientoModel>> build() async => const [];
}

void main() {
  testWidgets('Verificación de cero desbordamientos en PerfilScreen en pantalla 360x700', (tester) async {
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

    const user = UsuarioModel(
      id: 1,
      nombre: 'Santiago Gómez Casas',
      email: 'santiago@envejecer.com',
      rol: 'adulto_mayor',
      codigoVinculacion: 'ECB-1001',
    );

    const perfil = PerfilModel(
      edad: 75,
      peso: 62.0,
      altura: 158.0,
      genero: 'Masculino',
      tipoSangre: 'O+',
      eps: 'Sura',
      regimenEps: 'Contributivo',
      alergias: 'Ninguna',
      condiciones: 'Hipertensión',
      presionHabitual: '120/80 mmHg',
      nivelMovilidad: 'Independiente',
      numeroDocumento: '19458291',
      tipoDocumento: 'CC',
      contactoEmergenciaNombre: 'Carolina Gómez',
      contactoEmergenciaTelefono: '3001234567',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => FakeAuthNotifier(user: user)),
          perfilNotifierProvider.overrideWith(() => FakePerfilNotifier(perfil)),
          tratamientosNotifierProvider.overrideWith(FakeTratamientosNotifier.new),
        ],
        child: const MaterialApp(
          home: PerfilScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    for (int i = 0; i < errorList.length; i++) {
      debugPrint('ERROR #$i: ${errorList[i].exceptionAsString()}');
      if (errorList[i].informationCollector != null) {
        for (final info in errorList[i].informationCollector!()) {
          debugPrint('INFO: $info');
        }
      }
    }

    expect(errorList, isEmpty);
  });
}
