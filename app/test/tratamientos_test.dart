import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:envejecer_con_bienestar/core/utils/pdf_report_service.dart';
import 'package:envejecer_con_bienestar/features/auth/data/models/usuario_model.dart';
import 'package:envejecer_con_bienestar/features/home/data/models/meta_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/medicamento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/data/models/tratamiento_model.dart';
import 'package:envejecer_con_bienestar/features/medicamentos/presentation/widgets/tratamiento_card.dart';
import 'package:envejecer_con_bienestar/features/perfil/data/models/perfil_model.dart';
import 'package:envejecer_con_bienestar/features/perfil/presentation/widgets/carne_vital_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Pruebas Unitarias de Modelos Clínicos y Serialización', () {
    test('Serialización y deserialización de TratamientoModel con campos clínicos enriquecidos', () {
      final json = {
        'id': 101,
        'diagnostico': 'Hipertensión Arterial Grado II',
        'especialidad_medica': 'Cardiología',
        'medico_tratante': 'Dra. Sofía Rivas',
        'institucion_salud': 'Fundación Santa Fe',
        'fecha_inicio': '2026-01-10',
        'fecha_fin': '2026-12-31',
        'es_cronico': true,
        'estado': 'activo',
        'objetivo_terapeutico': 'Mantener TA < 130/80 mmHg',
        'notas_evolucion': 'Presión estable en último control.',
        'recomendaciones': 'Dieta hiposódica estricta y caminata 30 min.',
        'fecha_ultima_revision': '2026-08-15',
        'proxima_cita': '2026-11-20',
        'instrucciones': 'Tomar con abundante agua en ayunas.',
        'color': '#0D9488',
        'adherencia_porcentaje': 85.5,
        'medicamentos': [
          {
            'id': 1,
            'nombre': 'Losartán',
            'miligramos': '50',
            'frecuencia': 24,
            'cantidad_restante': 20,
            'esta_tomado': true,
          }
        ]
      };

      final model = TratamientoModel.fromJson(json);

      expect(model.id, equals(101));
      expect(model.diagnostico, equals('Hipertensión Arterial Grado II'));
      expect(model.especialidadMedica, equals('Cardiología'));
      expect(model.medicoTratante, equals('Dra. Sofía Rivas'));
      expect(model.institucionSalud, equals('Fundación Santa Fe'));
      expect(model.fechaInicio, equals('2026-01-10'));
      expect(model.esCronico, isTrue);
      expect(model.esActivo, isTrue);
      expect(model.esCompletado, isFalse);
      expect(model.esSuspendido, isFalse);
      expect(model.objetivoTerapeutico, equals('Mantener TA < 130/80 mmHg'));
      expect(model.notasEvolucion, equals('Presión estable en último control.'));
      expect(model.recomendaciones, equals('Dieta hiposódica estricta y caminata 30 min.'));
      expect(model.fechaUltimaRevision, equals('2026-08-15'));
      expect(model.proximaCita, equals('2026-11-20'));
      expect(model.color, equals('#0D9488'));
      expect(model.adherenciaPorcentaje, equals(85.5));
      expect(model.medicamentos.length, equals(1));
      expect(model.medicamentos.first.nombre, equals('Losartán'));

      // Comprobación de getters de texto
      expect(model.textoProgreso, equals('Tratamiento Permanente'));
      expect(model.textoEstado, equals('En curso'));

      // Prueba con tratamiento temporal
      const temporal = TratamientoModel(
        id: 102,
        diagnostico: 'Infección Respiratoria',
        esCronico: false,
        diasTranscurridos: 2,
        diasTotales: 7,
      );
      expect(temporal.textoProgreso, equals('Día 3 de 7'));
    });

    test('Serialización y lógica clínica de PerfilModel (IMC, completitud y clasificación)', () {
      final json = {
        'id': 1,
        'usuario_id': 42,
        'tipo_documento': 'CC',
        'numero_documento': '19482903',
        'fecha_nacimiento': '1951-03-15',
        'edad': 75,
        'genero': 'Masculino',
        'tipo_sangre': 'O+',
        'peso': 70.0,
        'altura': 170.0,
        'presion_habitual': '125/80 mmHg',
        'nivel_movilidad': 'Uso de bastón',
        'eps': 'SURA EPS',
        'regimen_eps': 'Contributivo',
        'telefono': '3009876543',
        'alergias': 'Penicilina, Sulfas',
        'condiciones': 'Hipertensión Arterial Grado II',
        'cirugias': 'Apendicectomía a los 25 años',
        'dispositivos_medicos': 'Bastón de un punto',
        'restricciones_alimentarias': 'Baja en sodio y azúcar',
        'antecedentes_familiares': 'Padre hipertenso, madre con DM2',
        'contacto_emergencia_nombre': 'Laura Gómez',
        'contacto_emergencia_telefono': '3001234567',
        'contacto_emergencia_parentesco': 'Hija',
        'medico_tratante': 'Dr. Fernando Salazar',
        'telefono_medico': '3157778899',
        'clinica_preferida': 'Clínica Las Américas',
        'acepto_habeas_data': true,
      };

      final perfil = PerfilModel.fromJson(json);

      expect(perfil.tipoDocumento, equals('CC'));
      expect(perfil.numeroDocumento, equals('19482903'));
      expect(perfil.edad, equals(75));
      expect(perfil.textoEdad, equals('75 años'));
      expect(perfil.genero, equals('Masculino'));
      expect(perfil.tipoSangre, equals('O+'));
      expect(perfil.eps, equals('SURA EPS'));
      expect(perfil.regimenEps, equals('Contributivo'));
      expect(perfil.alergias, equals('Penicilina, Sulfas'));
      expect(perfil.condiciones, equals('Hipertensión Arterial Grado II'));
      expect(perfil.restriccionesAlimentarias, equals('Baja en sodio y azúcar'));
      expect(perfil.antecedentesFamiliares, equals('Padre hipertenso, madre con DM2'));
      expect(perfil.contactoEmergenciaNombre, equals('Laura Gómez'));
      expect(perfil.contactoEmergenciaTelefono, equals('3001234567'));
      expect(perfil.contactoEmergenciaParentesco, equals('Hija'));
      expect(perfil.aceptoHabeasData, isTrue);

      // Verificación de IMC calculado: 70 / (1.70 * 1.70) = 24.22
      expect(perfil.imc, isNotNull);
      expect(perfil.imc!.toStringAsFixed(1), equals('24.2'));
      expect(perfil.clasificacionImc, equals('Peso saludable'));
      expect(perfil.colorImc, equals(const Color(0xFF22C55E)));

      // Verificación de completitud de la ficha médica
      expect(perfil.porcentajeCompletitud, greaterThanOrEqualTo(0.8));
      expect(perfil.porcentajeCompletitudEntero, greaterThanOrEqualTo(80));
    });
  });

  group('2. Pruebas de Widgets y Accesibilidad de Carné Vital (CarneVitalCard)', () {
    const testUser = UsuarioModel(
      id: 1,
      nombre: 'Don Jaime Casas',
      email: 'jaime@example.com',
      codigoVinculacion: 'ECB-9021',
      rol: 'adulto_mayor',
    );

    const testPerfil = PerfilModel(
      tipoDocumento: 'CC',
      numeroDocumento: '19482903',
      edad: 75,
      tipoSangre: 'O+',
      peso: 70.0,
      altura: 170.0,
      eps: 'SURA EPS',
      regimenEps: 'Contributivo',
      presionHabitual: '125/80 mmHg',
      nivelMovilidad: 'Uso de bastón',
      alergias: 'Penicilina',
      contactoEmergenciaNombre: 'Laura Cuidadora',
      contactoEmergenciaTelefono: '3001234567',
    );

    testWidgets('Renderizado de badges de triage con paleta no alarmista y métricas basales', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarneVitalCard(
                usuario: testUser,
                perfil: testPerfil,
              ),
            ),
          ),
        ),
      );

      // 1. Encabezado institucional y código de vinculación
      expect(find.text('CARNÉ VITAL DE SALUD'), findsOneWidget);
      expect(find.textContaining('ECB-9021'), findsOneWidget);
      expect(find.text('Don Jaime Casas'), findsOneWidget);
      expect(find.textContaining('CC 19482903'), findsOneWidget);
      expect(find.textContaining('75 años'), findsOneWidget);
      expect(find.textContaining('SURA EPS (Contributivo)'), findsOneWidget);

      // 2. Badge de Tipo de Sangre: verificar ausencia de rojo alarmista (usa rosa suave 0xFFFFE4E6 y carmesí 0xFF9F1239)
      final textSangre = find.text('Tipo: O+');
      expect(textSangre, findsOneWidget);
      final widgetTextSangre = tester.widget<Text>(textSangre);
      expect(widgetTextSangre.style?.color, equals(const Color(0xFF9F1239)));

      // 3. Badge de Alergias: verificar ausencia de rojo alarmista (usa ámbar suave 0xFFFEF3C7 y ámbar oscuro 0xFF92400E)
      final textAlergias = find.text('Alergias: Penicilina');
      expect(textAlergias, findsOneWidget);
      final widgetTextAlergias = tester.widget<Text>(textAlergias);
      expect(widgetTextAlergias.style?.color, equals(const Color(0xFF92400E)));

      // 4. Badge de IMC en cuadrícula simétrica
      expect(find.textContaining('IMC 24.2'), findsOneWidget);

      // 5. Métricas basales
      expect(find.textContaining('125/80 mmHg'), findsOneWidget);
      expect(find.textContaining('Uso de bastón'), findsOneWidget);
    });

    testWidgets('Botón SOS de marcación directa cumple touch target >= 56dp', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarneVitalCard(
                usuario: testUser,
                perfil: testPerfil,
              ),
            ),
          ),
        ),
      );

      // Buscar el botón SOS principal (ElevatedButton)
      final sosButtonFinder = find.byType(ElevatedButton);
      expect(sosButtonFinder, findsOneWidget);

      // Validar touch target de accesibilidad senior: altura >= 56dp
      final sosSize = tester.getSize(sosButtonFinder);
      expect(sosSize.height, greaterThanOrEqualTo(56.0));
      expect(find.textContaining('Llamar SOS: Laura Cuidadora'), findsOneWidget);
      expect(find.byIcon(Icons.phone_in_talk_rounded), findsOneWidget);
    });

    testWidgets('Sin contacto SOS configurado ofrece botón accesible de configuración', (WidgetTester tester) async {
      bool botonConfigurarPulsado = false;
      const perfilSinSos = PerfilModel(
        tipoDocumento: 'CC',
        numeroDocumento: '19482903',
        edad: 75,
        tipoSangre: 'O+',
        contactoEmergenciaTelefono: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarneVitalCard(
                usuario: testUser,
                perfil: perfilSinSos,
                onEditar: () {
                  botonConfigurarPulsado = true;
                },
              ),
            ),
          ),
        ),
      );

      final outlinedFinder = find.byType(OutlinedButton);
      expect(outlinedFinder, findsOneWidget);
      expect(find.text('Configurar Contacto SOS de Emergencia'), findsOneWidget);

      await tester.tap(outlinedFinder);
      await tester.pump();
      expect(botonConfigurarPulsado, isTrue);
    });
  });

  group('3. Pruebas de Widgets y Ergonomía de TratamientoCard', () {
    const medVinculado = Medicamento(
      id: 1,
      nombre: 'Enalapril',
      miligramos: '20',
      icono: '💊',
      estaTomado: true,
    );

    const tratamientoCronico = TratamientoModel(
      id: 201,
      diagnostico: 'Cardiopatía Isquémica',
      especialidadMedica: 'Cardiología',
      medicoTratante: 'Dr. Mendoza',
      institucionSalud: 'CardioVid',
      esCronico: true,
      objetivoTerapeutico: 'Prevenir eventos coronarios agudos',
      recomendaciones: 'Caminar 20 minutos diarios.',
      proximaCita: '15 de Diciembre 2026',
      medicamentos: [medVinculado],
    );

    const tratamientoTemporal = TratamientoModel(
      id: 202,
      diagnostico: 'Bronquitis Aguda',
      especialidadMedica: 'Neumología',
      esCronico: false,
      diasTranscurridos: 3,
      diasTotales: 10,
      progresoDias: 40.0,
    );

    testWidgets('Botones de acción directa con altura >= 52dp y sin menús ocultos de 3 puntos', (WidgetTester tester) async {
      bool toggleLlamado = false;
      bool deleteLlamado = false;
      bool editLlamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TratamientoCard(
                tratamiento: tratamientoCronico,
                onToggleEstado: () => toggleLlamado = true,
                onDelete: () => deleteLlamado = true,
                onEdit: () => editLlamado = true,
              ),
            ),
          ),
        ),
      );

      // 1. REGLA ESTRICTA DE ACCESIBILIDAD: Cero menús ocultos de tres puntos
      expect(find.byType(PopupMenuButton), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsNothing);

      // 2. Verificar que los 3 botones directos existan
      final botonCompletar = find.ancestor(
        of: find.text('Completar'),
        matching: find.byType(OutlinedButton),
      );
      final botonModificar = find.ancestor(
        of: find.text('Modificar'),
        matching: find.byType(OutlinedButton),
      );
      final botonEliminar = find.ancestor(
        of: find.byIcon(Icons.delete_outline),
        matching: find.byType(OutlinedButton),
      );

      expect(botonCompletar, findsOneWidget);
      expect(botonModificar, findsOneWidget);
      expect(botonEliminar, findsOneWidget);

      // 3. Validar altura táctil directa de botones >= 52dp
      expect(tester.getSize(botonCompletar).height, greaterThanOrEqualTo(52.0));
      expect(tester.getSize(botonModificar).height, greaterThanOrEqualTo(52.0));
      final sizeEliminar = tester.getSize(botonEliminar);
      expect(sizeEliminar.height, greaterThanOrEqualTo(52.0));
      expect(sizeEliminar.width, greaterThanOrEqualTo(52.0));

      // 4. Probar interacciones directas
      await tester.tap(botonCompletar);
      await tester.pump();
      expect(toggleLlamado, isTrue);

      await tester.tap(botonModificar);
      await tester.pump();
      expect(editLlamado, isTrue);

      await tester.tap(botonEliminar);
      await tester.pump();
      expect(deleteLlamado, isTrue);
    });

    testWidgets('Diferenciación visual accesible de Tratamiento Crónico vs Tratamiento Temporal', (WidgetTester tester) async {
      // Caso A: Tratamiento Crónico
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TratamientoCard(
                tratamiento: tratamientoCronico,
                onToggleEstado: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Terapia Permanente / Tratamiento Crónico'), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Cardiopatía Isquémica'), findsOneWidget);
      expect(find.text('Cardiología'), findsOneWidget);
      expect(find.text('Objetivo: Prevenir eventos coronarios agudos'), findsOneWidget);

      // Caso B: Tratamiento Temporal con barra de progreso
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TratamientoCard(
                tratamiento: tratamientoTemporal,
                onToggleEstado: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Terapia Permanente / Tratamiento Crónico'), findsNothing);
      expect(find.text('Día 4 de 10'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      final barraProgreso = find.byType(LinearProgressIndicator);
      expect(barraProgreso, findsOneWidget);
      final widgetBarra = tester.widget<LinearProgressIndicator>(barraProgreso);
      expect(widgetBarra.minHeight, equals(12.0));
    });
  });

  group('4. Pruebas de Lógica de Expediente Clínico PDF Digital (PdfReportService)', () {
    const testUser = UsuarioModel(
      id: 1,
      nombre: 'Don Jaime Casas',
      email: 'jaime@example.com',
      codigoVinculacion: 'ECB-9021',
      rol: 'adulto_mayor',
    );

    const testPerfil = PerfilModel(
      tipoDocumento: 'CC',
      numeroDocumento: '19482903',
      edad: 75,
      tipoSangre: 'O+',
      peso: 70.0,
      altura: 170.0,
      eps: 'SURA EPS',
      regimenEps: 'Contributivo',
      presionHabitual: '125/80 mmHg',
      nivelMovilidad: 'Uso de bastón',
      alergias: 'Penicilina',
      contactoEmergenciaNombre: 'Laura Cuidadora',
      contactoEmergenciaTelefono: '3001234567',
    );

    const testTratamiento = TratamientoModel(
      id: 1,
      diagnostico: 'Hipertensión Arterial',
      especialidadMedica: 'Cardiología',
      medicoTratante: 'Dr. Salazar',
      fechaInicio: '2026-01-01',
      esCronico: true,
      objetivoTerapeutico: 'TA < 130/80',
    );

    const testMed = Medicamento(
      id: 10,
      tratamientoId: 1,
      nombre: 'Losartán',
      miligramos: '50',
      frecuencia: 24,
      horaAlarma: '08:00',
      cantidadRestante: 28,
    );

    const testMeta = MetaModel(
      id: 1,
      usuarioId: 1,
      nombre: 'Caminar 20 minutos',
      objetivo: 20,
      progreso: 15,
      unidad: 'min',
    );

    test('Generación de documento PDF con incluirDocumento: false (resguardo de privacidad)', () async {
      final pdfDoc = PdfReportService.generarDocumentoPdf(
        usuario: testUser,
        perfil: testPerfil,
        tratamientos: [testTratamiento],
        medicamentos: [testMed],
        metas: [testMeta],
        incluirDocumento: false,
      );

      final Uint8List bytes = await pdfDoc.save();

      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.length, greaterThan(1000));
      // Verificar encabezado mágico de archivo PDF (%PDF)
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));
    });

    test('Generación de documento PDF con incluirDocumento: true (expediente formal con CC)', () async {
      final pdfDoc = PdfReportService.generarDocumentoPdf(
        usuario: testUser,
        perfil: testPerfil,
        tratamientos: [testTratamiento],
        medicamentos: [testMed],
        metas: [testMeta],
        incluirDocumento: true,
      );

      final Uint8List bytes = await pdfDoc.save();

      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.length, greaterThan(1000));
      // Verificar encabezado mágico de archivo PDF (%PDF)
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));
    });
  });
}
