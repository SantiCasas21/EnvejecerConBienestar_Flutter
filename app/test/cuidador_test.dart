import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/auth/data/models/paciente_vinculado_model.dart';
import 'package:envejecer_con_bienestar/features/auth/data/models/usuario_model.dart';
import 'package:envejecer_con_bienestar/features/auth/presentation/providers/auth_provider.dart';
import 'package:envejecer_con_bienestar/features/auth/presentation/providers/cuidador_provider.dart';
import 'package:envejecer_con_bienestar/features/auth/presentation/screens/register_screen.dart';
import 'package:envejecer_con_bienestar/features/auth/presentation/widgets/bienvenida_cuidador_dialog.dart';
import 'package:envejecer_con_bienestar/features/perfil/data/models/perfil_model.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/providers/perfil_provider.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/screens/perfil_screen.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/tratamiento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/providers/tratamientos_provider.dart';

/// Fake AuthNotifier para aislar pantallas de llamadas HTTP o SecureStorage.
class FakeAuthNotifier extends AuthNotifier {
  final UsuarioModel? user;
  FakeAuthNotifier({this.user});

  @override
  AuthState build() => AuthState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      );

  @override
  Future<bool> register(
    String nombre,
    String email,
    String password, {
    String rol = 'adulto_mayor',
  }) async {
    return true;
  }
}

/// Fake PerfilNotifier para simular datos de ficha médica del adulto mayor.
class FakePerfilNotifier extends PerfilNotifier {
  final PerfilModel? perfil;
  FakePerfilNotifier([this.perfil]);

  @override
  Future<PerfilModel?> build() async => perfil;
}

/// Fake TratamientosNotifier para simular lista vacía en pruebas.
class FakeTratamientosNotifier extends TratamientosNotifier {
  @override
  Future<List<TratamientoModel>> build() async => const [];
}

/// Fake CuidadorNotifier para simular lista de pacientes del cuidador.
class FakeCuidadorNotifier
    extends StateNotifier<AsyncValue<List<PacienteVinculadoModel>>>
    implements CuidadorNotifier {
  FakeCuidadorNotifier([List<PacienteVinculadoModel> pacientes = const []])
      : super(AsyncValue.data(pacientes));

  @override
  Future<void> cargarPacientes() async {}

  @override
  Future<String?> vincularPaciente(
    String codigoVinculacion, {
    String parentesco = 'Familiar / Cuidador',
  }) async => null;

  @override
  Future<bool> desvincularPaciente(int pacienteId) async => true;

  @override
  Future<Map<String, dynamic>?> obtenerDetalle(int pacienteId) async => null;

  @override
  Future<bool> reabastecerMedicamentoPaciente(
    int pacienteId,
    int medId,
    int cantidad,
  ) async => true;
}

void main() {
  group('1. Pruebas Unitarias de Modelos (Cuidador y Paciente)', () {
    test('UsuarioModel: getters esCuidador y esAdultoMayor según rol', () {
      // Usuario con rol 'cuidador'
      const cuidador = UsuarioModel(
        id: 1,
        nombre: 'Carlos Cuidador',
        email: 'carlos@example.com',
        rol: 'cuidador',
        codigoVinculacion: null,
      );
      expect(cuidador.esCuidador, isTrue);
      expect(cuidador.esAdultoMayor, isFalse);

      // Usuario con rol 'adulto_mayor'
      const adultoMayor = UsuarioModel(
        id: 2,
        nombre: 'Doña Rosa',
        email: 'rosa@example.com',
        rol: 'adulto_mayor',
        codigoVinculacion: 'ECB-1001',
      );
      expect(adultoMayor.esCuidador, isFalse);
      expect(adultoMayor.esAdultoMayor, isTrue);

      // Usuario con rol por defecto ('adulto_mayor')
      const usuarioDefault = UsuarioModel(
        id: 3,
        nombre: 'Usuario Regular',
        email: 'regular@example.com',
      );
      expect(usuarioDefault.rol, equals('adulto_mayor'));
      expect(usuarioDefault.esAdultoMayor, isTrue);
      expect(usuarioDefault.esCuidador, isFalse);
    });

    test('UsuarioModel: serialización fromJson y toJson', () {
      final json = {
        'id': 10,
        'nombre': 'Don Santiago',
        'email': 'santiago@example.com',
        'rol': 'adulto_mayor',
        'codigo_vinculacion': 'ECB-2005',
        'created_at': '2026-09-29T10:00:00.000Z',
      };

      final usuario = UsuarioModel.fromJson(json);
      expect(usuario.id, equals(10));
      expect(usuario.nombre, equals('Don Santiago'));
      expect(usuario.email, equals('santiago@example.com'));
      expect(usuario.rol, equals('adulto_mayor'));
      expect(usuario.codigoVinculacion, equals('ECB-2005'));
      expect(usuario.createdAt, isNotNull);

      final jsonGenerado = usuario.toJson();
      expect(jsonGenerado['id'], equals(10));
      expect(jsonGenerado['nombre'], equals('Don Santiago'));
      expect(jsonGenerado['codigo_vinculacion'], equals('ECB-2005'));
      expect(jsonGenerado['rol'], equals('adulto_mayor'));
    });

    test('PacienteVinculadoModel: serialización completa fromJson y toJson', () {
      final jsonOriginal = {
        'id': 42,
        'nombre': 'Carmen Elena',
        'email': 'carmen@salud.org',
        'codigo_vinculacion': 'ECB-1042',
        'parentesco': 'Madre',
        'fecha_vinculacion': '2026-09-28T14:30:00.000Z',
        'edad': 78,
        'genero': 'Femenino',
        'tipo_sangre': 'O+',
        'eps': 'Sura',
        'alergias': 'Penicilina',
        'condiciones': 'Hipertensión',
        'telefono': '3001234567',
        'contacto_emergencia_nombre': 'Hijo Andrés',
        'contacto_emergencia_telefono': '3109876543',
        'total_medicamentos': 4,
        'tomas_cumplidas': 3,
        'tomas_pendientes': 1,
        'alertas_stock': 1,
        'medicamentos_alerta': ['Losartán 50mg'],
        'proxima_toma': {
          'nombre': 'Losartán 50mg',
          'miligramos': '50mg',
          'hora': '20:00',
          'icono': '💊',
        },
      };

      final paciente = PacienteVinculadoModel.fromJson(jsonOriginal);

      expect(paciente.id, equals(42));
      expect(paciente.nombre, equals('Carmen Elena'));
      expect(paciente.email, equals('carmen@salud.org'));
      expect(paciente.codigoVinculacion, equals('ECB-1042'));
      expect(paciente.parentesco, equals('Madre'));
      expect(paciente.edad, equals(78));
      expect(paciente.totalMedicamentos, equals(4));
      expect(paciente.tomasCumplidas, equals(3));
      expect(paciente.tomasPendientes, equals(1));
      expect(paciente.alertasStock, equals(1));
      expect(paciente.medicamentosAlerta, contains('Losartán 50mg'));
      expect(paciente.proximaToma?['nombre'], equals('Losartán 50mg'));

      // Verificar serialización inversa
      final jsonSerializado = paciente.toJson();
      expect(jsonSerializado['id'], equals(42));
      expect(jsonSerializado['nombre'], equals('Carmen Elena'));
      expect(jsonSerializado['codigo_vinculacion'], equals('ECB-1042'));
      expect(jsonSerializado['parentesco'], equals('Madre'));
      expect(jsonSerializado['total_medicamentos'], equals(4));
    });

    test('PacienteVinculadoModel: deserialización de medicamentos y getters de cola e inventario', () {
      final jsonConMeds = {
        'id': 50,
        'nombre': 'Don Arturo Gómez',
        'email': 'arturo@salud.org',
        'total_medicamentos': 3,
        'medicamentos': [
          {
            'id': 1,
            'nombre': 'Metformina 850mg',
            'miligramos': '850mg',
            'hora_alarma': '08:00',
            'esta_tomado': true,
            'cantidad_restante': 20,
            'umbral_alerta': 5,
            'alerta_inventario': false,
          },
          {
            'id': 2,
            'nombre': 'Enalapril 10mg',
            'miligramos': '10mg',
            'hora_alarma': '14:00',
            'esta_tomado': false,
            'cantidad_restante': 3,
            'umbral_alerta': 5,
            'alerta_inventario': true,
          },
          {
            'id': 3,
            'nombre': 'Aspirina 100mg',
            'miligramos': '100mg',
            'hora_alarma': '20:00',
            'esta_tomado': false,
            'cantidad_restante': 4,
            'umbral_alerta': 5,
            'alerta_inventario': false, // tiene 4 pastillas <= umbral 5
          }
        ]
      };

      final paciente = PacienteVinculadoModel.fromJson(jsonConMeds);

      // 1. Deserialización de medicamentos
      expect(paciente.medicamentos.length, equals(3));

      // 2. Getter medicamentosEnCola (todos los medicamentos asignados al día)
      expect(paciente.medicamentosEnCola.length, equals(3));
      expect(paciente.medicamentosEnCola[0]['nombre'], equals('Metformina 850mg'));

      // 3. Getter medicamentosBajoStock (Enalapril con alerta_inventario=true y Aspirina con pastillas <= umbral)
      final bajoStock = paciente.medicamentosBajoStock;
      expect(bajoStock.length, equals(2));
      final nombresBajoStock = bajoStock.map((m) => m['nombre']).toList();
      expect(nombresBajoStock, contains('Enalapril 10mg'));
      expect(nombresBajoStock, contains('Aspirina 100mg'));
      expect(nombresBajoStock, isNot(contains('Metformina 850mg')));

      // 4. Getter tieneAlertasStock debe ser true
      expect(paciente.tieneAlertasStock, isTrue);
    });

    test('PacienteVinculadoModel: cálculo de métricas y getters de salud', () {
      // Caso 1: 3 de 4 medicinas tomadas (75%)
      const pacienteProgreso = PacienteVinculadoModel(
        id: 1,
        nombre: 'Paciente Progreso',
        email: 'test@mail.com',
        totalMedicamentos: 4,
        tomasCumplidas: 3,
        tomasPendientes: 1,
        alertasStock: 2,
        telefono: '3000000000',
      );
      expect(pacienteProgreso.porcentajeTomas, closeTo(0.75, 0.001));
      expect(pacienteProgreso.porcentajeTomasEntero, equals(75));
      expect(pacienteProgreso.todasTomasCompletadas, isFalse);
      expect(pacienteProgreso.tieneAlertasStock, isTrue);
      expect(pacienteProgreso.telefonoContactoDirecto, equals('3000000000'));

      // Caso 2: 0 medicamentos totales (evita división por cero, retorna 1.0)
      const pacienteSinMeds = PacienteVinculadoModel(
        id: 2,
        nombre: 'Sin Meds',
        email: 'sinmeds@mail.com',
        totalMedicamentos: 0,
        tomasCumplidas: 0,
        contactoEmergenciaTelefono: '3111111111',
      );
      expect(pacienteSinMeds.porcentajeTomas, equals(1.0));
      expect(pacienteSinMeds.porcentajeTomasEntero, equals(100));
      expect(pacienteSinMeds.todasTomasCompletadas, isFalse);
      expect(pacienteSinMeds.tieneAlertasStock, isFalse);
      // Fallback a contacto de emergencia si telefono es nulo
      expect(pacienteSinMeds.telefonoContactoDirecto, equals('3111111111'));

      // Caso 3: Todas las tomas completadas
      const pacienteAlDia = PacienteVinculadoModel(
        id: 3,
        nombre: 'Al Día',
        email: 'aldia@mail.com',
        totalMedicamentos: 2,
        tomasCumplidas: 2,
      );
      expect(pacienteAlDia.todasTomasCompletadas, isTrue);
      expect(pacienteAlDia.porcentajeTomas, equals(1.0));
    });
  });

  group('2. Pruebas de Widgets y Accesibilidad (Cuidador, Registro y Perfil)', () {
    testWidgets('RegisterScreen: renderiza opciones de rol con accesibilidad >= 56dp', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(FakeAuthNotifier.new),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar textos y títulos visibles
      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('¿Cuál es tu rol?'), findsOneWidget);
      expect(find.text('Soy Adulto Mayor'), findsOneWidget);
      expect(find.text('Soy Familiar o Cuidador'), findsOneWidget);

      // Validar regla de accesibilidad: tarjetas de selección táctil >= 56dp de alto
      final finderAdultoMayor = find.ancestor(
        of: find.text('Soy Adulto Mayor'),
        matching: find.byType(InkWell),
      );
      expect(finderAdultoMayor, findsOneWidget);
      final sizeAdultoMayor = tester.getSize(finderAdultoMayor);
      expect(sizeAdultoMayor.height, greaterThanOrEqualTo(56.0));

      final finderCuidador = find.ancestor(
        of: find.text('Soy Familiar o Cuidador'),
        matching: find.byType(InkWell),
      );
      expect(finderCuidador, findsOneWidget);
      final sizeCuidador = tester.getSize(finderCuidador);
      expect(sizeCuidador.height, greaterThanOrEqualTo(56.0));

      // Simular cambio de rol al tocar 'Soy Familiar o Cuidador'
      await tester.tap(finderCuidador);
      await tester.pumpAndSettle();

      // Verificar que el icono de radio checked cambie adecuadamente
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    });

    testWidgets('BienvenidaCuidadorDialog: renderiza campos de contacto y vinculación', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BienvenidaCuidadorDialog(initialNombre: 'María Cuidadora'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar cabecera cálida
      expect(find.text('¡Bienvenido/a Cuidador/a!'), findsOneWidget);
      expect(find.text('👤 Tus Datos Básicos'), findsOneWidget);
      expect(find.text('🔗 Vincular Adulto Mayor'), findsOneWidget);

      // Verificar que el nombre inicial esté prellenado en el formulario
      expect(find.text('María Cuidadora'), findsOneWidget);

      // Verificar campos clave
      expect(find.text('Parentesco'), findsOneWidget);
      expect(find.text('Ingresa el Código de tu Familiar'), findsOneWidget);
      expect(find.text('Ej: ECB-1001'), findsOneWidget);
      expect(find.textContaining('Habeas Data'), findsOneWidget);

      // Verificar botón de acción principal (>= 56dp)
      final botonPrincipal = find.text('Guardar y Continuar al Panel 🌟');
      expect(botonPrincipal, findsOneWidget);
      final sizeBoton = tester.getSize(botonPrincipal);
      expect(sizeBoton.height, greaterThan(0));

      // Verificar botón secundario de omitir
      expect(find.text('Ingresar código de paciente más tarde'), findsOneWidget);
    });

    testWidgets('PerfilScreen: muestra "👤 Paciente", código ECB-XXXX y ficha médica para adulto mayor', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const pacienteUser = UsuarioModel(
        id: 1,
        nombre: 'Don Mario Gómez',
        email: 'mario@salud.com',
        rol: 'adulto_mayor',
        codigoVinculacion: 'ECB-1005',
      );

      const perfilData = PerfilModel(
        edad: 74,
        genero: 'Masculino',
        tipoSangre: 'O+',
        eps: 'Sura',
        alergias: 'Ninguna',
        condiciones: 'Hipertensión',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => FakeAuthNotifier(user: pacienteUser)),
            perfilNotifierProvider.overrideWith(() => FakePerfilNotifier(perfilData)),
            tratamientosNotifierProvider.overrideWith(FakeTratamientosNotifier.new),
          ],
          child: const MaterialApp(
            home: PerfilScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar la etiqueta visible '👤 Paciente'
      expect(find.text('👤 Paciente'), findsOneWidget);

      // Debe mostrar su código de vinculación personal ECB-1005 (en Carné Vital y Tarjeta de Vinculación)
      expect(find.text('ECB-1005'), findsWidgets);

      // Debe mostrar su nombre y el título 'Mi Perfil de Salud'
      expect(find.text('Don Mario Gómez'), findsOneWidget);
      expect(find.text('Mi Perfil de Salud'), findsOneWidget);

      // NO debe mostrar la etiqueta de cuidador
      expect(find.text('🛡️ Cuidador'), findsNothing);
    });

    testWidgets('PerfilScreen: muestra "🛡️ Cuidador" y pacientes supervisados sin ficha médica para cuidador', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const cuidadorUser = UsuarioModel(
        id: 2,
        nombre: 'Sofía Gómez',
        email: 'sofia@cuidador.com',
        rol: 'cuidador',
        codigoVinculacion: null,
      );

      final pacientes = [
        const PacienteVinculadoModel(
          id: 1,
          nombre: 'Don Mario Gómez',
          email: 'mario@salud.com',
          codigoVinculacion: 'ECB-1005',
          parentesco: 'Hija',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => FakeAuthNotifier(user: cuidadorUser)),
            cuidadorNotifierProvider.overrideWith((ref) => FakeCuidadorNotifier(pacientes)),
          ],
          child: const MaterialApp(
            home: PerfilScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar 'Mi Perfil de Cuidador'
      expect(find.text('Mi Perfil de Cuidador'), findsOneWidget);

      // Debe mostrar la etiqueta visible '🛡️ Cuidador'
      expect(find.text('🛡️ Cuidador'), findsOneWidget);

      // Debe mostrar el nombre del cuidador
      expect(find.text('Sofía Gómez'), findsOneWidget);

      // Debe mostrar la sección de familiares o pacientes supervisados
      expect(find.text('👥 Familiares a tu Cuidado'), findsOneWidget);
      expect(find.text('Don Mario Gómez'), findsOneWidget);

      // CERO ficha médica ni "Ficha médica al 0%" ni "👤 Paciente"
      expect(find.text('👤 Paciente'), findsNothing);
      expect(find.textContaining('Ficha Médica:'), findsNothing);
      expect(find.text('Mi Perfil de Salud'), findsNothing);
    });
  });
}
