import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/features/contactos/data/models/contacto_model.dart';
import 'package:envejecer_con_bienestar/features/contactos/data/repositories/contacto_repository.dart';
import 'package:envejecer_con_bienestar/features/contactos/presentation/screens/contacto_detail_screen.dart';
import 'package:envejecer_con_bienestar/features/contactos/presentation/screens/contactos_screen.dart';

class FakeContactoRepository extends ContactoRepository {
  List<Contacto> items;
  Contacto? lastUpdated;

  FakeContactoRepository(this.items) : super(Dio());

  @override
  Future<List<Contacto>> getContactos() async => items;

  @override
  Future<Contacto> updateContacto(int id, Map<String, dynamic> data) async {
    final idx = items.indexWhere((c) => c.id == id);
    final updated = Contacto(
      id: id,
      nombre: data['nombre'] ?? items[idx].nombre,
      telefono: data['telefono'] ?? items[idx].telefono,
      ubicacion: data['ubicacion'] ?? items[idx].ubicacion,
      categoria: data['categoria'] ?? items[idx].categoria,
      esFavorito: data['es_favorito'] ?? items[idx].esFavorito,
      esEmergencia: data['es_emergencia'] ?? items[idx].esEmergencia,
    );
    if (idx != -1) items[idx] = updated;
    lastUpdated = updated;
    return updated;
  }
}

void main() {
  final sampleContactos = [
    const Contacto(
      id: 1,
      nombre: 'Dra. Claudia Ortiz',
      telefono: '3001112233',
      ubicacion: 'Clínica del Norte',
      categoria: 'Médico',
      esEmergencia: true,
      esFavorito: true,
    ),
    const Contacto(
      id: 2,
      nombre: 'Andrés Pérez',
      telefono: '3104445566',
      ubicacion: 'Casa Familiar',
      categoria: 'Familia/Amigos',
      esEmergencia: false,
      esFavorito: true,
    ),
    const Contacto(
      id: 3,
      nombre: 'Vecina Marta',
      telefono: '3207778899',
      categoria: 'Vecino/Otro',
    ),
  ];

  testWidgets('ContactosScreen renderiza sin overflow en 360x700 con TextScaler 1.2 y filtra correctamente',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeContactoRepository(List.of(sampleContactos));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactoRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.2)),
            child: ContactosScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis Contactos'), findsOneWidget);
    expect(find.text('Sincronizar con mi Celular'), findsOneWidget);
    expect(find.text('Dra. Claudia Ortiz'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Vecina Marta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Vecina Marta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Volver arriba para ver los filtros
    await tester.drag(find.byType(ListView).first, const Offset(0, 500));
    await tester.pumpAndSettle();

    // Filtrar por Emergencia
    await tester.tap(find.text('🚨 Emergencia (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Dra. Claudia Ortiz'), findsOneWidget);
    expect(find.text('Vecina Marta'), findsNothing);

    // Volver a Todos y buscar por texto
    await tester.tap(find.text('Todos (3)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Andrés');
    await tester.pumpAndSettle();
    expect(find.text('Andrés Pérez'), findsOneWidget);
    expect(find.text('Dra. Claudia Ortiz'), findsNothing);
  });

  testWidgets('ContactoDetailScreen muestra perfil tipo celular y permite toggle rápido de Favorito y SOS',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeContactoRepository(List.of(sampleContactos));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactoRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ContactoDetailScreen(id: '3'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil de Contacto'), findsOneWidget);
    expect(find.text('Vecina Marta'), findsOneWidget);
    expect(find.text('3207778899'), findsOneWidget);
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Toggle rápido a Favorito
    await tester.tap(find.text('Hacer Fav.'));
    await tester.pumpAndSettle();
    expect(repo.lastUpdated?.esFavorito, isTrue);

    // Toggle rápido a SOS
    await tester.tap(find.text('Poner SOS'));
    await tester.pumpAndSettle();
    expect(repo.lastUpdated?.esEmergencia, isTrue);
  });
}
