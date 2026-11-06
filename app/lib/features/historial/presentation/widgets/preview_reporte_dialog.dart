import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/whatsapp_report_service.dart';
import '../../data/models/resumen_adherencia_model.dart';

/// Diálogo de vista previa antes de compartir el reporte por WhatsApp
class PreviewReporteDialog extends StatelessWidget {
  final String nombrePaciente;
  final ResumenAdherenciaModel resumen;
  final String? periodoNombre;

  const PreviewReporteDialog({
    super.key,
    required this.nombrePaciente,
    required this.resumen,
    this.periodoNombre,
  });

  @override
  Widget build(BuildContext context) {
    final mensaje = WhatsAppReportService.construirMensajeReporte(
      nombrePaciente: nombrePaciente,
      resumen: resumen,
      periodoNombre: periodoNombre,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.share_rounded, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vista Previa del Reporte',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Formato amigable para WhatsApp',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar texto',
                    icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: mensaje));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            '📋 Reporte copiado al portapapeles.',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppColors.primaryTeal,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Contenedor tipo burbuja de chat de WhatsApp con scroll
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        mensaje,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF14532D),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop(true);
                          await WhatsAppReportService.compartirPorWhatsApp(
                            nombrePaciente: nombrePaciente,
                            resumen: resumen,
                            periodoNombre: periodoNombre,
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: const Text(
                          'Enviar a WhatsApp',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
