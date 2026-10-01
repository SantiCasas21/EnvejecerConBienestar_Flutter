import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/medicamentos/data/models/medicamento_model.dart';
import '../../features/medicamentos/data/models/tratamiento_model.dart';
import '../../features/home/data/models/meta_model.dart';
import '../../features/perfil/data/models/perfil_model.dart';
import '../../features/auth/data/models/usuario_model.dart';

class PdfReportService {
  static pw.Document generarDocumentoPdf({
    required UsuarioModel usuario,
    required PerfilModel? perfil,
    required List<TratamientoModel> tratamientos,
    required List<Medicamento> medicamentos,
    required List<MetaModel> metas,
    bool incluirDocumento = false,
  }) {
    final pdf = pw.Document();

    // Paleta Institucional Calma y Vitalidad (.NET MAUI / Flutter)
    const tealPrimary = PdfColor.fromInt(0xFF0D9488);
    const tealDark = PdfColor.fromInt(0xFF0F766E);
    const tealLight = PdfColor.fromInt(0xFFCCFBF1);
    const lavenderSecondary = PdfColor.fromInt(0xFF818CF8);
    const lavenderLight = PdfColor.fromInt(0xFFE0E7FF);
    const redEmergency = PdfColor.fromInt(0xFFE11D48);
    const redLight = PdfColor.fromInt(0xFFFFE4E6);
    const textDark = PdfColor.fromInt(0xFF1E293B);
    const greyBg = PdfColor.fromInt(0xFFF8FAFC);
    const greyBorder = PdfColor.fromInt(0xFFCBD5E1);

    final now = DateTime.now();
    final fechaStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final horaStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Separar medicamentos asociados a tratamientos de los no vinculados
    final idsTratamientos = tratamientos.map((t) => t.id).toSet();
    final medicamentosLibres = medicamentos.where((m) => m.tratamientoId == null || !idsTratamientos.contains(m.tratamientoId)).toList();

    final alergiasRaw = perfil?.alergias.trim();
    final tieneAlergias = alergiasRaw != null &&
        alergiasRaw.isNotEmpty &&
        alergiasRaw.toLowerCase() != 'ninguna';
    final alergiasTexto = (alergiasRaw != null && alergiasRaw.isNotEmpty)
        ? alergiasRaw
        : 'Ninguna alergia registrada';
    final docNum = perfil?.numeroDocumento?.trim();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // ── SECCIÓN 1: MEMBRETE INSTITUCIONAL Y FICHA DE TRIAGE VITAL ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EXPEDIENTE MÉDICO DIGITAL',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: tealDark),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Envejecer con Bienestar — Sistema de Soporte y Salud Personalizada',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Documento clínico digital consolidado para consulta médica, enfermería y urgencias',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: tealDark, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: tealLight,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('EMISIÓN: $fechaStr $horaStr', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: tealDark)),
                      if (usuario.codigoVinculacion != null)
                        pw.Text('CÓDIGO: ${usuario.codigoVinculacion}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: tealDark),
            pw.SizedBox(height: 10),

            // Ficha Vital del Paciente
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: greyBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: greyBorder, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('1. DATOS DE IDENTIDAD Y MÉTRICAS BASALES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: tealDark)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: redLight,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: redEmergency, width: 0.8),
                        ),
                        child: pw.Text(
                          'GRUPO SANGUÍNEO: ${perfil?.tipoSangre ?? "O+"}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: redEmergency),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Paciente: ${usuario.nombre}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: textDark))),
                      pw.Expanded(
                        child: pw.Text(
                          (incluirDocumento && docNum != null && docNum.isNotEmpty)
                              ? 'Documento: ${perfil?.tipoDocumento ?? "CC"} $docNum'
                              : 'Documento: Omitido por privacidad',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: textDark,
                            fontStyle: (incluirDocumento && docNum != null && docNum.isNotEmpty) ? pw.FontStyle.normal : pw.FontStyle.italic,
                          ),
                        ),
                      ),
                      pw.Expanded(child: pw.Text('Edad: ${perfil?.textoEdad ?? "No especificada"} (${perfil?.genero ?? "N/A"})', style: const pw.TextStyle(fontSize: 10, color: textDark))),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'EPS: ${perfil?.eps ?? "No registrada"} (${perfil?.regimenEps ?? "Contributivo"})',
                          style: const pw.TextStyle(fontSize: 10, color: textDark),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Presión Habitual: ${perfil?.presionHabitual?.isNotEmpty == true ? perfil!.presionHabitual : "120/80 mmHg"}',
                          style: const pw.TextStyle(fontSize: 10, color: textDark),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Movilidad: ${perfil?.nivelMovilidad?.isNotEmpty == true ? perfil!.nivelMovilidad : "Independiente"}',
                          style: const pw.TextStyle(fontSize: 10, color: textDark),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          perfil?.imc != null 
                              ? 'IMC: ${perfil!.imc!.toStringAsFixed(1)} kg/m² (${perfil.clasificacionImc})' 
                              : 'IMC: No registrado',
                          style: const pw.TextStyle(fontSize: 10, color: textDark),
                        ),
                      ),
                      pw.Expanded(child: pw.Text('Teléfono: ${perfil?.telefono ?? "No registrado"}', style: const pw.TextStyle(fontSize: 10, color: textDark))),
                      pw.Expanded(child: pw.Text('Email: ${usuario.email}', style: const pw.TextStyle(fontSize: 10, color: textDark))),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Alerta Crítica de Alergias y Urgencias
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: pw.BoxDecoration(
                color: tieneAlergias ? redLight : greyBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: tieneAlergias ? redEmergency : greyBorder,
                  width: 1,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ALERGIAS Y ADVERTENCIAS:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: tieneAlergias ? redEmergency : textDark,
                          ),
                        ),
                        pw.Text(
                          alergiasTexto,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: tieneAlergias ? pw.FontWeight.bold : pw.FontWeight.normal,
                            color: tieneAlergias ? redEmergency : textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CONTACTO SOS URGENCIAS:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: redEmergency)),
                        pw.Text(
                          '${perfil?.contactoEmergenciaNombre ?? "Familiar"} (${perfil?.contactoEmergenciaParentesco ?? "Contacto"}): ${perfil?.contactoEmergenciaTelefono ?? "Sin registrar"}',
                          style: const pw.TextStyle(fontSize: 9, color: textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── SECCIÓN 2: MATRIZ DE TRATAMIENTOS CLÍNICOS Y DIAGNÓSTICOS FORMALES ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('2. TRATAMIENTOS CLÍNICOS Y DIAGNÓSTICOS VIGENTES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
                pw.Text('${tratamientos.length} registrados', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 6),

            if (tratamientos.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: greyBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: greyBorder),
                ),
                child: pw.Text('No hay tratamientos clínicos registrados actualmente.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              )
            else
              ...tratamientos.map((t) {
                final esCronico = t.esCronico ?? false;
                final medsTratamiento = medicamentos.where((m) => m.tratamientoId == t.id).toList();

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: greyBg,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: greyBorder, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Encabezado del tratamiento
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Diagnóstico: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: tealDark)),
                                  pw.TextSpan(text: t.diagnostico, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: textDark)),
                                  if (t.especialidadMedica != null && t.especialidadMedica!.isNotEmpty)
                                    pw.TextSpan(text: ' [${t.especialidadMedica}]', style: const pw.TextStyle(fontSize: 9, color: PdfColors.teal800)),
                                ],
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: esCronico ? tealLight : lavenderLight,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              esCronico ? 'CRÓNICO / PERMANENTE' : 'TEMPORAL (${t.textoProgreso})',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: esCronico ? tealDark : lavenderSecondary),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'Médico: ${t.medicoTratante ?? "Particular"} • Inicio: ${t.fechaInicio}${t.fechaFin != null ? " • Fin: ${t.fechaFin}" : ""}',
                              style: const pw.TextStyle(fontSize: 8.5, color: textDark),
                            ),
                          ),
                          if (t.proximaCita != null && t.proximaCita!.isNotEmpty)
                            pw.Text('Próxima Cita: ${t.proximaCita}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: tealDark)),
                        ],
                      ),
                      if (t.objetivoTerapeutico != null && t.objetivoTerapeutico!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Objetivo Terapéutico: ${t.objetivoTerapeutico}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                      ],
                      if (t.recomendaciones != null && t.recomendaciones!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Recomendaciones Médicas: ${t.recomendaciones}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                      ],

                      // Medicamentos vinculados a este tratamiento
                      if (medsTratamiento.isNotEmpty) ...[
                        pw.SizedBox(height: 5),
                        pw.Text('Prescripción Farmacológica Asociada:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
                        pw.SizedBox(height: 2),
                        pw.TableHelper.fromTextArray(
                          headers: ['Medicamento', 'Dosis', 'Frecuencia', 'Horario', 'Inventario'],
                          data: medsTratamiento.map((m) => [
                            m.nombre,
                            m.miligramos != null ? '${m.miligramos} mg' : '-',
                            'Cada ${m.frecuencia ?? 24} h',
                            m.horaAlarma ?? 'Horario regular',
                            '${m.cantidadRestante ?? 0} unidades',
                          ]).toList(),
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                          headerDecoration: const pw.BoxDecoration(color: tealPrimary),
                          cellStyle: const pw.TextStyle(fontSize: 7.5),
                          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 10),

            // ── SECCIÓN 3: MEDICAMENTOS ADICIONALES Y BOTIQUÍN ──
            if (medicamentosLibres.isNotEmpty || tratamientos.isEmpty) ...[
              pw.Text('3. OTROS MEDICAMENTOS Y BOTIQUÍN SOS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: ['Medicamento', 'Dosis', 'Frecuencia', 'Horario / Instrucción', 'Inventario'],
                data: (tratamientos.isEmpty ? medicamentos : medicamentosLibres).map((m) => [
                  m.nombre,
                  m.miligramos != null ? '${m.miligramos} mg' : '-',
                  'Cada ${m.frecuencia ?? 24} h',
                  m.horaAlarma ?? 'Horario regular',
                  '${m.cantidadRestante ?? 0} unidades',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: tealPrimary),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
              pw.SizedBox(height: 10),
            ],

            // ── SECCIÓN 4: HÁBITOS DE VIDA Y METAS DE BIENESTAR ──
            if (metas.isNotEmpty) ...[
              pw.Text('4. HÁBITOS DE VIDA SALUDABLE Y SEGUIMIENTO', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: ['Hábito / Meta', 'Progreso Actual', 'Objetivo', 'Cumplimiento', 'Estado'],
                data: metas.map((m) => [
                  m.nombre,
                  '${m.progreso} ${m.unidad}',
                  '${m.objetivo} ${m.unidad}',
                  '${(m.porcentaje * 100).toInt()}%',
                  m.completada ? 'Cumplida' : 'En seguimiento',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: tealDark),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
              pw.SizedBox(height: 10),
            ],

            // ── SECCIÓN 5: RESUMEN CLÍNICO CONSOLIDADO (FORMATO DIGITAL PURO) ──
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: tealDark, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
                color: greyBg,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '5. ANTECEDENTES Y RESUMEN CLÍNICO CONSOLIDADO',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: tealDark),
                      ),
                      pw.Text(
                        'Registro Digital Seguro',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (perfil?.antecedentesFamiliares != null && perfil!.antecedentesFamiliares!.isNotEmpty) ...[
                    pw.Text('• Antecedentes Familiares: ${perfil.antecedentesFamiliares}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                    pw.SizedBox(height: 2),
                  ],
                  if (perfil?.restriccionesAlimentarias != null && perfil!.restriccionesAlimentarias!.isNotEmpty) ...[
                    pw.Text('• Restricciones Alimentarias / Dieta: ${perfil.restriccionesAlimentarias}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                    pw.SizedBox(height: 2),
                  ],
                  if (perfil?.cirugias != null && perfil!.cirugias.isNotEmpty && perfil.cirugias != 'Ninguna') ...[
                    pw.Text('• Cirugías Previas: ${perfil.cirugias}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                    pw.SizedBox(height: 2),
                  ],
                  if (perfil?.dispositivosMedicos != null && perfil!.dispositivosMedicos.isNotEmpty && perfil.dispositivosMedicos != 'Ninguno') ...[
                    pw.Text('• Dispositivos de Apoyo: ${perfil.dispositivosMedicos}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                    pw.SizedBox(height: 2),
                  ],
                  if (perfil?.notasAdicionales != null && perfil!.notasAdicionales!.isNotEmpty) ...[
                    pw.Text('• Notas de Cuidado: ${perfil.notasAdicionales}', style: const pw.TextStyle(fontSize: 8.5, color: textDark)),
                    pw.SizedBox(height: 2),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 0.6, color: greyBorder),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Expediente consolidado automáticamente por la plataforma "Envejecer con Bienestar" para conciliación farmacológica y apoyo en consulta médica. Información suministrada bajo consentimiento informado del usuario.',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Pie de Página ──
            pw.Divider(thickness: 0.8, color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Expediente Médico Oficial Digital — Ley 1581 de 2012 (Habeas Data y Protección de Datos Sensibles). Confidencial.',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static Future<void> generarYCompartirReporte({
    required UsuarioModel usuario,
    required PerfilModel? perfil,
    required List<TratamientoModel> tratamientos,
    required List<Medicamento> medicamentos,
    required List<MetaModel> metas,
    bool incluirDocumento = false,
  }) async {
    final pdf = generarDocumentoPdf(
      usuario: usuario,
      perfil: perfil,
      tratamientos: tratamientos,
      medicamentos: medicamentos,
      metas: metas,
      incluirDocumento: incluirDocumento,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Expediente_Clinico_${usuario.nombre.replaceAll(' ', '_')}.pdf',
    );
  }
}
