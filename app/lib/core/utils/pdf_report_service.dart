import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/medicamentos/data/models/medicamento_model.dart';
import '../../features/home/data/models/meta_model.dart';
import '../../features/perfil/data/models/perfil_model.dart';
import '../../features/auth/data/models/usuario_model.dart';

class PdfReportService {
  static Future<void> generarYCompartirReporte({
    required UsuarioModel usuario,
    required PerfilModel? perfil,
    required List<Medicamento> medicamentos,
    required List<MetaModel> metas,
  }) async {
    final pdf = pw.Document();

    // Paleta Calma y Vitalidad en PDF
    const tealPrimary = PdfColor.fromInt(0xFF0D9488);
    const tealLight = PdfColor.fromInt(0xFFCCFBF1);
    const redEmergency = PdfColor.fromInt(0xFFE11D48);
    const textDark = PdfColor.fromInt(0xFF1E293B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // ── Encabezado Institucional ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORME MEDICO PERSONAL',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: tealPrimary),
                    ),
                    pw.Text(
                      'Envejecer con Bienestar — Aplicacion de Apoyo y Salud',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Hora: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: tealPrimary),
            pw.SizedBox(height: 12),

            // ── Ficha del Paciente y Datos Vitales ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: tealLight,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DEL PACIENTE Y FICHA VITAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Nombre: ${usuario.nombre}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: textDark))),
                      pw.Expanded(child: pw.Text('Email: ${usuario.email}', style: const pw.TextStyle(color: textDark))),
                    ],
                  ),
                  if (perfil != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text('Edad: ${perfil.textoEdad}', style: const pw.TextStyle(color: textDark))),
                        pw.Expanded(child: pw.Text('Tipo de Sangre: ${perfil.tipoSangre ?? "O+"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: redEmergency))),
                        pw.Expanded(child: pw.Text('Genero: ${perfil.genero}', style: const pw.TextStyle(color: textDark))),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text('EPS / Aseguradora: ${perfil.eps}', style: const pw.TextStyle(color: textDark))),
                        pw.Expanded(
                          child: pw.Text(
                            perfil.imc != null 
                                ? 'IMC: ${perfil.imc!.toStringAsFixed(1)} kg/m2 (${perfil.clasificacionImc})' 
                                : 'IMC: No registrado',
                            style: const pw.TextStyle(color: textDark),
                          ),
                        ),
                        pw.Expanded(child: pw.Text('Telefono: ${perfil.telefono ?? "No registrado"}', style: const pw.TextStyle(color: textDark))),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Alergias Conocidas: ${perfil.alergias}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: redEmergency)),
                    pw.Text('Condiciones Medicas / Diagnosticos: ${perfil.condiciones}', style: const pw.TextStyle(color: textDark)),
                    if (perfil.cirugias.isNotEmpty && perfil.cirugias != 'Ninguna')
                      pw.Text('Cirugias / Antecedentes: ${perfil.cirugias}', style: const pw.TextStyle(color: textDark)),
                    if (perfil.dispositivosMedicos.isNotEmpty && perfil.dispositivosMedicos != 'Ninguno')
                      pw.Text('Dispositivos de Apoyo: ${perfil.dispositivosMedicos}', style: const pw.TextStyle(color: textDark)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Red de Emergencia y Contactos ──
            if (perfil != null && (perfil.contactoEmergenciaTelefono?.isNotEmpty == true || perfil.medicoTratante?.isNotEmpty == true)) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: redEmergency, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    if (perfil.contactoEmergenciaTelefono?.isNotEmpty == true)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('CONTACTO DE EMERGENCIA SOS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: redEmergency)),
                            pw.Text('${perfil.contactoEmergenciaNombre ?? "Familiar"} (${perfil.contactoEmergenciaParentesco}): ${perfil.contactoEmergenciaTelefono}'),
                          ],
                        ),
                      ),
                    if (perfil.medicoTratante?.isNotEmpty == true)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('MEDICO TRATANTE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
                            pw.Text('${perfil.medicoTratante} — Tel: ${perfil.telefonoMedico ?? "N/A"}'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
            ],

            // ── Tabla de Medicamentos ──
            pw.Text('TRATAMIENTO Y MEDICAMENTOS ACTUALES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
            pw.SizedBox(height: 6),
            if (medicamentos.isEmpty)
              pw.Text('No hay medicamentos registrados en el sistema.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Medicamento', 'Dosis', 'Frecuencia', 'Estado Diario', 'Stock Restante'],
                data: medicamentos.map((m) => [
                  m.nombre,
                  m.miligramos != null ? '${m.miligramos} mg' : '-',
                  'Cada ${m.frecuencia ?? 24} horas',
                  (m.estaTomado ?? false) ? 'Tomado' : 'Pendiente',
                  '${m.cantidadRestante ?? 0} pastillas',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: tealPrimary),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
            pw.SizedBox(height: 14),

            // ── Metas y Hábitos ──
            pw.Text('HABITOS DE VIDA SALUDABLE Y METAS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealPrimary)),
            pw.SizedBox(height: 6),
            if (metas.isEmpty)
              pw.Text('No hay metas de salud activas.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Actividad / Meta', 'Progreso', 'Objetivo', 'Cumplimiento', 'Estado'],
                data: metas.map((m) => [
                  m.nombre,
                  '${m.progreso} ${m.unidad}',
                  '${m.objetivo} ${m.unidad}',
                  '${(m.porcentaje * 100).toInt()}%',
                  m.completada ? 'Cumplida' : 'En progreso',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: tealPrimary),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
            pw.SizedBox(height: 20),

            // ── Pie de Página ──
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Documento medico generado por Envejecer con Bienestar — Para uso clinico y de emergencia.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Informe_Medico_${usuario.nombre.replaceAll(' ', '_')}.pdf',
    );
  }
}
