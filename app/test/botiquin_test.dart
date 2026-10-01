import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/contactos/data/models/contacto_model.dart';
import 'package:envejecer_con_bienestar/features/contactos/data/repositories/contacto_repository.dart';
import 'package:envejecer_con_bienestar/features/contactos/presentation/providers/contactos_provider.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/medicamento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/botiquin_inventario_tab.dart';
import 'package:envejecer_con_bienestar/features/perfil/data/models/perfil_model.dart';
import 'package:envejecer_con_bienestar/features/perfil/data/repositories/perfil_repository.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/providers/perfil_provider.dart';

/// Fake ContactoRepository para registrar llamadas a getContactos
class FakeContactoRepository implements ContactoRepository {
  int llamadasGetContactos = 0;

  @override
  Future<List<Contacto>> getContactos() async {
    llamadasGetContactos++;
    return [
      const Contacto(
        id: 1,
        nombre: 'Contacto SOS',
        telefono: '3001234567',
        esEmergencia: true,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake PerfilRepository para aislar la prueba de llamadas a red
class FakePerfilRepository implements PerfilRepository {
  @override
  Future<PerfilModel?> getPerfil() async => const PerfilModel(edad: 75);

  @override
  Future<PerfilModel> guardarPerfil(Map<String, dynamic> data) async {
    return const PerfilModel(
      edad: 75,
      contactoEmergenciaNombre: 'Hijo SOS',
      contactoEmergenciaTelefono: '3109876543',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('1. Pruebas Unitarias de Lógica de Inventario (Medicamento)', () {
    test('Cálculo de diasAutonomia según tomas diarias y stock disponible', () {
      // 1 toma cada 24 horas (1 al día): 15 pastillas = 15 días
      const med24h = Medicamento(
        id: 1,
        nombre: 'Losartán 50mg',
        frecuencia: 24,
        cantidadRestante: 15,
        umbralAlerta: 5,
      );
      expect(med24h.tomasPorDia, equals(1));
      expect(med24h.diasAutonomia, equals(15));

      // 1 toma cada 12 horas (2 al día): 20 pastillas = 10 días
      const med12h = Medicamento(
        id: 2,
        nombre: 'Metformina 850mg',
        frecuencia: 12,
        cantidadRestante: 20,
        umbralAlerta: 5,
      );
      expect(med12h.tomasPorDia, equals(2));
      expect(med12h.diasAutonomia, equals(10));

      // 1 toma cada 8 horas iniciando 06:00 (3 al día: 06:00, 14:00, 22:00): 30 pastillas = 10 días
      const med8h = Medicamento(
        id: 3,
        nombre: 'Amoxicilina 500mg',
        frecuencia: 8,
        horaAlarma: '06:00',
        cantidadRestante: 30,
        umbralAlerta: 5,
      );
      expect(med8h.tomasPorDia, equals(3));
      expect(med8h.diasAutonomia, equals(10));

      // Casos borde: agotado o null retorna 0 días
      const medAgotado = Medicamento(
        id: 4,
        nombre: 'Sin Stock',
        frecuencia: 8,
        cantidadRestante: 0,
      );
      expect(medAgotado.diasAutonomia, equals(0));

      const medNull = Medicamento(
        id: 5,
        nombre: 'Stock Null',
        cantidadRestante: null,
      );
      expect(medNull.diasAutonomia, equals(0));
    });

    test('Cálculo de alertaInventario, textoInventario y nivelStock', () {
      // Caso 1: Stock Óptimo (30 pastillas con umbral 5)
      const medOptimo = Medicamento(
        id: 1,
        nombre: 'Vitamina C',
        frecuencia: 24,
        cantidadRestante: 30,
        umbralAlerta: 5,
      );
      expect(medOptimo.alertaInventario, isFalse);
      expect(medOptimo.textoInventario, equals('Quedan 30 pastillas'));
      expect(medOptimo.nivelStock, equals('optimo'));

      // Caso 2: Stock Bajo (exactamente 5 pastillas <= umbral 5, y 5 días de autonomía <= 7)
      const medEnUmbral = Medicamento(
        id: 2,
        nombre: 'Enalapril 10mg',
        frecuencia: 24,
        cantidadRestante: 5,
        umbralAlerta: 5,
      );
      expect(medEnUmbral.alertaInventario, isTrue);
      expect(medEnUmbral.textoInventario, equals('Quedan 5 pastillas'));
      expect(medEnUmbral.nivelStock, equals('bajo'));

      // Caso 3: Stock Crítico (1 pastilla con 1 al día = 1 día de autonomía)
      const medCritico = Medicamento(
        id: 3,
        nombre: 'Atorvastatina',
        frecuencia: 24,
        cantidadRestante: 1,
        umbralAlerta: 5,
      );
      expect(medCritico.alertaInventario, isTrue);
      expect(medCritico.nivelStock, equals('critico'));

      // Caso 4: Agotado (0 pastillas)
      const medCero = Medicamento(
        id: 4,
        nombre: 'Insulina',
        cantidadRestante: 0,
        umbralAlerta: 5,
      );
      expect(medCero.alertaInventario, isFalse); // Agotado, no en alerta
      expect(medCero.textoInventario, equals('Sin pastillas disponibles'));
      expect(medCero.nivelStock, equals('agotado'));
    });
  });

  group('2. Pruebas de Widgets de Botiquín (BotiquinInventarioTab)', () {
    testWidgets('Renderizado de tarjetas tipo blíster, insignias, barras y botones táctiles', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final reabastecimientosRealizados = <Map<String, dynamic>>[];

      final listaMedicamentos = [
        const Medicamento(
          id: 101,
          nombre: 'Metformina',
          miligramos: '850',
          frecuencia: 12,
          cantidadRestante: 25,
          umbralAlerta: 5,
          icono: '💊',
        ),
        const Medicamento(
          id: 102,
          nombre: 'Losartán',
          miligramos: '50',
          frecuencia: 24,
          cantidadRestante: 4,
          umbralAlerta: 5,
          icono: '🩺',
        ),
        const Medicamento(
          id: 103,
          nombre: 'Atorvastatina',
          miligramos: '20',
          frecuencia: 24,
          cantidadRestante: 0,
          umbralAlerta: 5,
          icono: '❤️',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BotiquinInventarioTab(
                medicamentos: listaMedicamentos,
                onReabastecer: (medId, cantidad, nombre) async {
                  reabastecimientosRealizados.add({
                    'id': medId,
                    'cantidad': cantidad,
                    'nombre': nombre,
                  });
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verificar cabecera y contadores con semáforo
      expect(find.text('Mi Botiquín'), findsOneWidget);
      expect(find.text('Stock óptimo'), findsOneWidget);
      expect(find.text('Por reponer'), findsOneWidget);
      expect(find.text('Agotados'), findsOneWidget);

      // 2. Verificar insignias de semáforo de inventario
      expect(find.text('🟢 Stock Óptimo'), findsOneWidget);
      expect(find.text('⚠️ Stock Bajo (≤ 5)'), findsOneWidget);
      expect(find.text('🔴 Agotado'), findsOneWidget);

      // 3. Verificar que las barras de nivel de stock existan (LinearProgressIndicator)
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

      // 4. Verificar botones de reabastecimiento rápido (+10 y +30)
      final botones10 = find.text('+10 pastillas');
      final botones30 = find.text('+30 (1 Caja)');
      expect(botones10, findsNWidgets(3));
      expect(botones30, findsNWidgets(3));

      // 5. Validar accesibilidad táctil: altura mínima de botones >= 46dp
      final boton10Widget = find.ancestor(
        of: find.text('+10 pastillas').first,
        matching: find.byType(OutlinedButton),
      );
      final sizeBoton10 = tester.getSize(boton10Widget);
      expect(sizeBoton10.height, greaterThanOrEqualTo(46.0));

      final boton30Widget = find.ancestor(
        of: find.text('+30 (1 Caja)').first,
        matching: find.byType(ElevatedButton),
      );
      final sizeBoton30 = tester.getSize(boton30Widget);
      expect(sizeBoton30.height, greaterThanOrEqualTo(46.0));

      // 6. Probar interacción de reabastecimiento rápido al tocar +10
      await tester.tap(botones10.first);
      await tester.pump();

      expect(reabastecimientosRealizados.length, equals(1));
      expect(reabastecimientosRealizados[0]['id'], equals(101));
      expect(reabastecimientosRealizados[0]['cantidad'], equals(10));
      expect(reabastecimientosRealizados[0]['nombre'], equals('Metformina'));

      // 7. Probar interacción de reabastecimiento rápido al tocar +30 (1 Caja) en Losartán
      await tester.tap(botones30.at(1));
      await tester.pump();

      expect(reabastecimientosRealizados.length, equals(2));
      expect(reabastecimientosRealizados[1]['id'], equals(102));
      expect(reabastecimientosRealizados[1]['cantidad'], equals(30));
      expect(reabastecimientosRealizados[1]['nombre'], equals('Losartán'));
    });
  });

  group('3. Prueba de Reactividad: Invalidación Automática de Proveedores', () {
    test('La actualización de perfil invalida contactosNotifierProvider sin reiniciar la app', () async {
      final fakeContactoRepo = FakeContactoRepository();
      final fakePerfilRepo = FakePerfilRepository();

      final container = ProviderContainer(
        overrides: [
          contactoRepositoryProvider.overrideWithValue(fakeContactoRepo),
          perfilRepositoryProvider.overrideWithValue(fakePerfilRepo),
        ],
      );
      addTearDown(container.dispose);

      // 1. Carga inicial de contactos (debe ejecutar getContactos una vez)
      await container.read(contactosNotifierProvider.future);
      expect(fakeContactoRepo.llamadasGetContactos, equals(1));

      // 2. Modificamos la ficha médica / perfil (ej: actualización de datos de contacto de emergencia)
      const nuevoPerfil = PerfilModel(
        edad: 76,
        contactoEmergenciaNombre: 'Hermana SOS',
        contactoEmergenciaTelefono: '3009998877',
      );
      container.read(perfilNotifierProvider.notifier).actualizarPerfil(nuevoPerfil);

      // 3. Al invalidar contactosNotifierProvider, se dispara una nueva consulta automática
      await container.read(contactosNotifierProvider.future);
      expect(fakeContactoRepo.llamadasGetContactos, equals(2));

      // 4. Verificamos también con guardarPerfil
      await container.read(perfilNotifierProvider.notifier).guardarPerfil({
        'contacto_emergencia_nombre': 'Hijo SOS',
        'contacto_emergencia_telefono': '3109876543',
      });

      await container.read(contactosNotifierProvider.future);
      expect(fakeContactoRepo.llamadasGetContactos, equals(3));
    });
  });
}
