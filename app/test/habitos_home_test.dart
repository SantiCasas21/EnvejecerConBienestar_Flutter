import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:envejecer_con_bienestar/features/auth/data/models/usuario_model.dart';
import 'package:envejecer_con_bienestar/features/auth/presentation/providers/auth_provider.dart';
import 'package:envejecer_con_bienestar/features/contactos/data/models/contacto_model.dart';
import 'package:envejecer_con_bienestar/features/contactos/presentation/providers/contactos_provider.dart';
import 'package:envejecer_con_bienestar/features/home/data/models/meta_model.dart';
import 'package:envejecer_con_bienestar/features/home/presentation/providers/metas_provider.dart';
import 'package:envejecer_con_bienestar/features/home/presentation/screens/home_screen.dart';
import 'package:envejecer_con_bienestar/features/home/presentation/widgets/add_meta_dialog.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/medicamento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/providers/medicamentos_provider.dart';
import 'package:envejecer_con_bienestar/features/perfil/data/models/perfil_model.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/providers/perfil_provider.dart';

// ── Fakes para Riverpod ──

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

class FakeMedicamentosNotifier extends MedicamentosNotifier {
  final List<Medicamento> medicamentos;
  FakeMedicamentosNotifier(this.medicamentos);

  @override
  Future<List<Medicamento>> build() async => medicamentos;

  @override
  Future<void> toggleTomado(dynamic id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == id ? m.copyWith(estaTomado: !(m.estaTomado ?? false)) : m).toList(),
    );
  }
}

class FakeMetasNotifier extends MetasNotifier {
  final List<MetaModel> metas;
  FakeMetasNotifier(this.metas);

  @override
  Future<List<MetaModel>> build() async => metas;

  @override
  Future<void> incrementarProgreso(int id, {int valor = 1}) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) {
        if (m.id == id) {
          final nuevoProgreso = (m.progreso + valor).clamp(0, 999);
          final completada = nuevoProgreso >= m.objetivo;
          return m.copyWith(progreso: nuevoProgreso, completada: completada);
        }
        return m;
      }).toList(),
    );
  }

  @override
  Future<void> addMeta(Map<String, dynamic> data) async {
    final current = state.value ?? [];
    final nueva = MetaModel(
      id: current.length + 1,
      usuarioId: 1,
      nombre: data['nombre'] as String,
      objetivo: data['objetivo'] as int,
      progreso: data['progreso'] as int? ?? 0,
      unidad: data['unidad'] as String? ?? 'vasos',
      icono: data['icono'] as String? ?? '🎯',
    );
    state = AsyncValue.data([nueva, ...current]);
  }
}

class FakeContactosNotifier extends ContactosNotifier {
  @override
  Future<List<Contacto>> build() async => const [];
}

void main() {
  const testUser = UsuarioModel(
    id: 1,
    nombre: 'Esperanza Gómez',
    email: 'esperanza@bienestar.com',
    rol: 'adulto_mayor',
    codigoVinculacion: 'ECB-1005',
  );

  const testPerfil = PerfilModel(
    edad: 73,
    peso: 60,
    altura: 155,
    genero: 'Femenino',
    tipoSangre: 'O+',
    eps: 'Sanitas',
    alergias: 'Ninguna',
    condiciones: 'Hipertensión leve',
    contactoEmergenciaNombre: 'María Gómez',
    contactoEmergenciaTelefono: '3009876543',
  );

  final List<Medicamento> testMedicamentos = [
    const Medicamento(
      id: 1,
      nombre: 'Losartán',
      miligramos: '50mg',
      frecuencia: 12,
      icono: '💊',
      colorIcono: '#0D9488',
      estaTomado: false,
    ),
  ];

  final testMetas8Pilares = [
    const MetaModel(id: 1, usuarioId: 1, nombre: 'Tomar agua', objetivo: 8, progreso: 3, unidad: 'vasos', icono: '💧'),
    const MetaModel(id: 2, usuarioId: 1, nombre: 'Caminata y paseo', objetivo: 30, progreso: 15, unidad: 'minutos', icono: '🚶'),
    const MetaModel(id: 3, usuarioId: 1, nombre: 'Sol y Vitamina D', objetivo: 15, progreso: 0, unidad: 'minutos', icono: '☀️'),
    const MetaModel(id: 4, usuarioId: 1, nombre: 'Estiramientos suaves', objetivo: 10, progreso: 0, unidad: 'minutos', icono: '🧘'),
    const MetaModel(id: 5, usuarioId: 1, nombre: 'Sueño reparador', objetivo: 8, progreso: 7, unidad: 'horas', icono: '😴'),
    const MetaModel(id: 6, usuarioId: 1, nombre: 'Fruta y verdura', objetivo: 3, progreso: 1, unidad: 'porciones', icono: '🥗'),
    const MetaModel(id: 7, usuarioId: 1, nombre: 'Llamada familiar', objetivo: 1, progreso: 0, unidad: 'charla', icono: '📞'),
    const MetaModel(id: 8, usuarioId: 1, nombre: 'Gimnasio mental', objetivo: 15, progreso: 10, unidad: 'minutos', icono: '🧠'),
  ];

  Widget buildHomeScreenTestWidget({List<MetaModel>? metas}) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => FakeAuthNotifier(user: testUser)),
        perfilNotifierProvider.overrideWith(() => FakePerfilNotifier(testPerfil)),
        medicamentosNotifierProvider.overrideWith(() => FakeMedicamentosNotifier(testMedicamentos)),
        metasNotifierProvider.overrideWith(() => FakeMetasNotifier(metas ?? testMetas8Pilares)),
        contactosNotifierProvider.overrideWith(FakeContactosNotifier.new),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('Pruebas de HomeScreen: Refactor Visual y Selector de Pestañas', () {
    testWidgets('1. Pestaña "Mi Día y Salud" renderiza saludo, SOS, medicinas y resumen de hábitos', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeScreenTestWidget());
      await tester.pumpAndSettle();

      // Saludo y usuario
      expect(find.textContaining('Esperanza'), findsOneWidget);

      // Selector de pestañas
      expect(find.text('Mi Día y Salud'), findsOneWidget);
      expect(find.text('Hábitos Vitales'), findsOneWidget);

      // Botón SOS Prominente (72dp)
      expect(find.text('BOTÓN SOS DE EMERGENCIA'), findsOneWidget);
      final sosFinder = find.widgetWithText(ElevatedButton, 'BOTÓN SOS DE EMERGENCIA');
      expect(sosFinder, findsOneWidget);
      final sosSize = tester.getSize(sosFinder);
      expect(sosSize.height, greaterThanOrEqualTo(72.0));

      // Medicinas de hoy y próxima dosis pendiente
      expect(find.text('💊 Medicinas de Hoy'), findsOneWidget);
      expect(find.text('Losartán'), findsOneWidget);
      expect(find.text('Tomar'), findsOneWidget);

      // Gimnasio Mental y Juegos
      expect(find.text('Gimnasio Mental y Juegos'), findsOneWidget);

      // Mini Resumen de Hábitos de Hoy
      expect(find.text('Hábitos de Hoy'), findsOneWidget);
      expect(find.text('Explorar y Registrar Mis Hábitos ➔'), findsOneWidget);
    });

    testWidgets('2. Conmutación fluida entre pestañas al tocar la píldora o el botón de resumen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeScreenTestWidget());
      await tester.pumpAndSettle();

      // Inicialmente en pestaña 0
      expect(find.text('BOTÓN SOS DE EMERGENCIA'), findsOneWidget);

      // Tocar botón "Explorar y Registrar Mis Hábitos ➔"
      final botonResumen = find.text('Explorar y Registrar Mis Hábitos ➔');
      await tester.ensureVisible(botonResumen);
      await tester.tap(botonResumen);
      await tester.pumpAndSettle();

      // Ahora debe mostrar la vista de Hábitos de Bienestar
      expect(find.text('Vitalidad y Hábitos Diarios'), findsOneWidget);
      expect(find.text('🌱 Mis Hábitos Activos'), findsOneWidget);
      expect(find.text('Hidratación Vital'), findsOneWidget);

      // Regresar a "Mi Día y Salud" tocando la píldora superior
      await tester.tap(find.text('Mi Día y Salud'));
      await tester.pumpAndSettle();

      expect(find.text('BOTÓN SOS DE EMERGENCIA'), findsOneWidget);
    });

    testWidgets('3. Pestaña "Hábitos Vitales" renderiza catálogo interactivo de los 8 pilares', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeScreenTestWidget());
      await tester.pumpAndSettle();

      // Cambiar a Hábitos Vitales
      await tester.tap(find.text('Hábitos Vitales'));
      await tester.pumpAndSettle();

      // Verificar títulos de los 8 hábitos interactivos
      expect(find.text('Hidratación Vital'), findsOneWidget);
      expect(find.text('Caminata y Movimiento Activo'), findsOneWidget);
      expect(find.text('Baño de Sol y Vitamina D'), findsOneWidget);
      expect(find.text('Pausas Activas y Estiramientos'), findsOneWidget);
      expect(find.text('Sueño Reparador'), findsOneWidget);
      expect(find.text('Nutrición y Frutas Frescas'), findsOneWidget);
      expect(find.text('Afecto y Conexión Familiar'), findsOneWidget);
      expect(find.text('Gimnasio Mental y Lectura'), findsOneWidget);

      // Botón ancho para crear hábito personalizado
      expect(find.text('Crear Hábito Personalizado'), findsOneWidget);
    });

    testWidgets('4. Interacción con tarjeta de Hidratación: pulsar "Tomar 1 Vaso de Agua" incrementa progreso', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeScreenTestWidget());
      await tester.pumpAndSettle();

      // Ir a hábitos
      await tester.tap(find.text('Hábitos Vitales'));
      await tester.pumpAndSettle();

      // Estado inicial de agua: "3 de 8 vasos tomados hoy"
      expect(find.text('3 de 8 vasos tomados hoy'), findsOneWidget);

      // Tocar botón de sumar vaso
      final botonVaso = find.widgetWithText(ElevatedButton, 'Tomar 1 Vaso de Agua');
      expect(botonVaso, findsOneWidget);
      await tester.tap(botonVaso);
      await tester.pumpAndSettle();

      // Debe incrementarse a 4
      expect(find.text('4 de 8 vasos tomados hoy'), findsOneWidget);
    });

    testWidgets('5. Modal AddMetaDialog: sugerencias de hábitos, botones [-] y [+] de cantidad', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMetaDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Hábito de Bienestar'), findsOneWidget);
      expect(find.text('Elige un hábito recomendado:'), findsOneWidget);

      // Sugerencias
      expect(find.text('Caminata y paseo'), findsOneWidget);
      expect(find.text('Sol y Vitamina D'), findsOneWidget);

      // Contador inicial (8 vasos)
      expect(find.text('8'), findsOneWidget);
      expect(find.text('vasos'), findsOneWidget);

      // Tocar botón [+] para incrementar objetivo
      final iconAdd = find.byIcon(Icons.add_rounded);
      expect(iconAdd, findsOneWidget);
      await tester.tap(iconAdd);
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);

      // Seleccionar chip "Caminata y paseo"
      await tester.tap(find.text('Caminata y paseo'));
      await tester.pumpAndSettle();

      // Debe actualizarse el objetivo a 30 y unidad a minutos
      expect(find.text('30'), findsOneWidget);
      expect(find.text('minutos'), findsOneWidget);
    });

    testWidgets('6. Verificación de cero desbordamientos (RenderFlex) en pantalla 360x700 con escala de texto', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.2),
            size: Size(360, 700),
          ),
          child: buildHomeScreenTestWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Cambiar a Pestaña 1
      await tester.tap(find.text('Hábitos Vitales'));
      await tester.pumpAndSettle();

      // Scroll para recorrer las tarjetas
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
