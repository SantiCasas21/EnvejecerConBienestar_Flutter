import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/medicamento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/tratamiento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/repositories/medicamento_repository.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/providers/medicamentos_provider.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/add_tratamiento_dialog.dart';

/// Fake repository para aislar pruebas de llamadas HTTP
class FakeMedicamentoRepository implements MedicamentoRepository {
  final List<Medicamento> medicamentos;

  FakeMedicamentoRepository(this.medicamentos);

  @override
  Future<List<Medicamento>> getMedicamentos({int? tratamientoId}) async {
    return medicamentos;
  }

  @override
  Future<Medicamento> createMedicamento(Map<String, dynamic> data) async {
    final newMed = Medicamento(
      id: medicamentos.length + 100,
      nombre: data['nombre'] as String,
      miligramos: data['miligramos'] as String?,
      frecuencia: data['frecuencia'] as int? ?? 24,
      cantidadRestante: data['cantidad_restante'] as int? ?? 30,
      umbralAlerta: data['umbral_alerta'] as int? ?? 5,
      icono: data['icono'] as String? ?? '💊',
    );
    medicamentos.add(newMed);
    return newMed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake notifier para controlar el estado de medicamentos en Riverpod
class FakeMedicamentosNotifier extends MedicamentosNotifier {
  final List<Medicamento> initialMedicamentos;

  FakeMedicamentosNotifier(this.initialMedicamentos);

  @override
  Future<List<Medicamento>> build() async {
    return initialMedicamentos;
  }

  @override
  Future<void> addMedicamento(Map<String, dynamic> data) async {
    final repo = ref.read(medicamentoRepositoryProvider);
    final newMed = await repo.createMedicamento(data);
    final current = state.value ?? [];
    state = AsyncValue.data([newMed, ...current]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Pruebas Unitarias de Formateo de Nombre y Gramaje (nombreConDosis)', () {
    test('Evita duplicar gramaje cuando el nombre ya contiene los miligramos (ej. Metformina 850mg)', () {
      const med1 = Medicamento(
        id: 1,
        nombre: 'Metformina 850mg',
        miligramos: '850 mg',
      );
      expect(med1.nombreConDosis, equals('Metformina 850mg'));
      expect(med1.nombreConDosis, isNot(contains('(850 mgmg)')));
      expect(med1.nombreConDosis, isNot(contains('(850 mg)')));

      const med2 = Medicamento(
        id: 2,
        nombre: 'Losartán 50 mg',
        miligramos: '50mg',
      );
      expect(med2.nombreConDosis, equals('Losartán 50 mg'));
      expect(med2.nombreConDosis, isNot(contains('(50mgmg)')));
    });

    test('Limpia y normaliza dosis con unidades pegadas o duplicadas', () {
      const medNormal = Medicamento(
        id: 3,
        nombre: 'Losartán Potásico',
        miligramos: '50mg',
      );
      // Debe formatear a '50 mg' con espacio y sin duplicar 'mg'
      expect(medNormal.nombreConDosis, equals('Losartán Potásico (50 mg)'));
      expect(medNormal.nombreConDosis, isNot(contains('mgmg')));

      const medDuplicado = Medicamento(
        id: 4,
        nombre: 'Enalapril',
        miligramos: '20 mgmg',
      );
      expect(medDuplicado.nombreConDosis, equals('Enalapril (20 mg)'));
    });

    test('Maneja correctamente dosis puramente numéricas, unidades distintas a mg y valores nulos', () {
      const medNumeroSolo = Medicamento(
        id: 5,
        nombre: 'Atorvastatina',
        miligramos: '20',
      );
      expect(medNumeroSolo.nombreConDosis, equals('Atorvastatina (20 mg)'));

      const medInsulina = Medicamento(
        id: 6,
        nombre: 'Insulina Glargina',
        miligramos: '10 UI',
      );
      expect(medInsulina.nombreConDosis, equals('Insulina Glargina (10 UI)'));

      const medSinDosis = Medicamento(
        id: 7,
        nombre: 'Acetaminofén',
        miligramos: null,
      );
      expect(medSinDosis.nombreConDosis, equals('Acetaminofén'));
    });
  });

  group('2. Pruebas de Widget en AddTratamientoDialog (Selección Dinámica y Cero Bloqueo)', () {
    late List<Medicamento> testMeds;

    setUp(() {
      testMeds = [
        const Medicamento(
          id: 1,
          nombre: 'Metformina 850mg',
          miligramos: '850 mg',
        ),
        const Medicamento(
          id: 2,
          nombre: 'Losartán',
          miligramos: '50mg',
        ),
        const Medicamento(
          id: 3,
          nombre: 'Atorvastatina',
          miligramos: '20',
        ),
      ];
    });

    Widget buildTestWidget({TratamientoModel? tratamiento}) {
      final fakeRepo = FakeMedicamentoRepository(testMeds);
      return ProviderScope(
        overrides: [
          medicamentoRepositoryProvider.overrideWithValue(fakeRepo),
          medicamentosNotifierProvider.overrideWith(() => FakeMedicamentosNotifier(testMeds)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddTratamientoDialog(tratamiento: tratamiento),
          ),
        ),
      );
    }

    testWidgets('Chips de medicamentos renderizan con nombres limpios sin gramajes ni unidades duplicadas', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verificar que los chips aparezcan
      expect(find.text('Metformina 850mg'), findsOneWidget);
      expect(find.text('Losartán (50 mg)'), findsOneWidget);
      expect(find.text('Atorvastatina (20 mg)'), findsOneWidget);

      // Cero duplicaciones grotescas como (850 mgmg) o (50mgmg)
      expect(find.textContaining('mgmg'), findsNothing);
      expect(find.textContaining('(850 mgmg)'), findsNothing);
      expect(find.textContaining('Metformina 850mg (850 mg)'), findsNothing);
    });

    testWidgets('Permite seleccionar y deseleccionar medicamentos interactivamente sin estar bloqueado/fijo', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final chipLosartan = find.widgetWithText(FilterChip, 'Losartán (50 mg)');
      expect(chipLosartan, findsOneWidget);

      // Inicialmente desmarcado
      FilterChip chipWidget = tester.widget<FilterChip>(chipLosartan);
      expect(chipWidget.selected, isFalse);

      // Tap para seleccionar
      await tester.ensureVisible(chipLosartan);
      await tester.tap(chipLosartan);
      await tester.pumpAndSettle();

      chipWidget = tester.widget<FilterChip>(chipLosartan);
      expect(chipWidget.selected, isTrue);

      // Tap nuevamente para deseleccionar
      await tester.tap(chipLosartan);
      await tester.pumpAndSettle();

      chipWidget = tester.widget<FilterChip>(chipLosartan);
      expect(chipWidget.selected, isFalse);
    });

    testWidgets('Permite ingresar y asociar un nuevo medicamento al vuelo con "+ Escribir nuevo"', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Botón para desplegar formulario rápido
      final botonNuevo = find.text('+ Escribir nuevo');
      expect(botonNuevo, findsOneWidget);

      await tester.tap(botonNuevo);
      await tester.pumpAndSettle();

      // El formulario debe ser visible
      expect(find.text('Escribe los datos del medicamento para asociarlo:'), findsOneWidget);
      expect(find.text('Nombre del medicamento'), findsOneWidget);
      expect(find.text('Dosis o Gramaje (opcional)'), findsOneWidget);

      // Escribir datos del nuevo medicamento
      final inputs = find.byType(TextFormField);
      // Buscar los campos específicos por hint/label
      final campoNombre = find.widgetWithText(TextFormField, 'Nombre del medicamento');
      final campoDosis = find.widgetWithText(TextFormField, 'Dosis o Gramaje (opcional)');

      await tester.enterText(campoNombre, 'Amlodipino');
      await tester.enterText(campoDosis, '5 mg');
      await tester.pumpAndSettle();

      // Guardar y asociar
      final botonGuardarAsociar = find.text('Guardar y Asociar');
      expect(botonGuardarAsociar, findsOneWidget);
      await tester.ensureVisible(botonGuardarAsociar);
      await tester.tap(botonGuardarAsociar);
      await tester.pumpAndSettle();

      // Verificar que el nuevo chip se haya creado y esté seleccionado automáticamente
      final chipNuevo = find.widgetWithText(FilterChip, 'Amlodipino (5 mg)');
      expect(chipNuevo, findsOneWidget);
      final chipNuevoWidget = tester.widget<FilterChip>(chipNuevo);
      expect(chipNuevoWidget.selected, isTrue);
    });

    testWidgets('Al editar un tratamiento existente, carga medicamentos vinculados preseleccionados y permite modificarlos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final tratamientoExistente = TratamientoModel(
        id: 42,
        diagnostico: 'Hipertensión Arterial Primaria',
        especialidadMedica: 'Cardiología',
        medicoTratante: 'Dra. Gómez',
        esCronico: true,
        medicamentos: [
          const Medicamento(
            id: 2,
            nombre: 'Losartán',
            miligramos: '50mg',
          ),
        ],
      );

      Map<String, dynamic>? resultadoPop;

      final fakeRepo = FakeMedicamentoRepository(testMeds);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicamentoRepositoryProvider.overrideWithValue(fakeRepo),
            medicamentosNotifierProvider.overrideWith(() => FakeMedicamentosNotifier(testMeds)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    resultadoPop = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (ctx) => AddTratamientoDialog(tratamiento: tratamientoExistente),
                    );
                  },
                  child: const Text('Abrir Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Tratamiento Clínico'), findsOneWidget);

      // Losartán (id: 2) debe estar preseleccionado
      final chipLosartan = find.widgetWithText(FilterChip, 'Losartán (50 mg)');
      expect(chipLosartan, findsOneWidget);
      FilterChip widgetLosartan = tester.widget<FilterChip>(chipLosartan);
      expect(widgetLosartan.selected, isTrue);

      // Atorvastatina (id: 3) debe estar desmarcado
      final chipAtorvastatina = find.widgetWithText(FilterChip, 'Atorvastatina (20 mg)');
      expect(chipAtorvastatina, findsOneWidget);
      FilterChip widgetAtorva = tester.widget<FilterChip>(chipAtorvastatina);
      expect(widgetAtorva.selected, isFalse);

      // Desmarcar Losartán y marcar Atorvastatina
      await tester.ensureVisible(chipLosartan);
      await tester.tap(chipLosartan);
      await tester.pumpAndSettle();
      await tester.ensureVisible(chipAtorvastatina);
      await tester.tap(chipAtorvastatina);
      await tester.pumpAndSettle();

      widgetLosartan = tester.widget<FilterChip>(chipLosartan);
      expect(widgetLosartan.selected, isFalse);
      widgetAtorva = tester.widget<FilterChip>(chipAtorvastatina);
      expect(widgetAtorva.selected, isTrue);

      // Pulsar 'Actualizar'
      final botonActualizar = find.text('Actualizar');
      expect(botonActualizar, findsOneWidget);
      await tester.ensureVisible(botonActualizar);
      await tester.tap(botonActualizar);
      await tester.pumpAndSettle();

      // Verificar que el payload retornado tenga medicamento_ids con id: 3 y sin id: 2
      expect(resultadoPop, isNotNull);
      expect(resultadoPop!['diagnostico'], equals('Hipertensión Arterial Primaria'));
      expect(resultadoPop!['medicamento_ids'], equals([3]));
    });
  });
}
