import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';

class HabeasDataDialog extends StatelessWidget {
  const HabeasDataDialog({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const HabeasDataDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.cardBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, size: 28, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Política de Habeas Data',
                          style: AppTypography.titulo().copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ley 1581 de 2012 • República de Colombia',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1.5, color: AppColors.border),

              // ── Contenido con Scroll ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _seccion(
                        titulo: '1. Responsable del Tratamiento',
                        texto: 'La aplicación "Envejecer con Bienestar" actúa como responsable del tratamiento de los datos personales y de salud suministrados por los usuarios y sus cuidadores.',
                      ),
                      _seccion(
                        titulo: '2. Tratamiento de Datos Sensibles de Salud',
                        texto: 'De conformidad con el Artículo 5 de la Ley 1581 de 2012, la información sobre tu estado de salud, medicamentos, tratamientos médicos, tipo de sangre, alergias y diagnósticos clínicos se cataloga como DATO SENSIBLE.\n\nComo titular, tienes derecho a contestar o no a las preguntas sobre datos sensibles. Sin embargo, su ingreso es indispensable para garantizar el cálculo exacto de tus alarmas de medicinas, la generación de tu ficha clínica y la activación de emergencias SOS.',
                      ),
                      _seccion(
                        titulo: '3. Finalidades Exclusivas',
                        texto: 'Tus datos son tratados exclusivamente para:\n'
                            '• Programar y personalizar recordatorios y alarmas sonoras de tomas de medicamentos.\n'
                            '• Monitorear la adherencia a tus tratamientos médicos prescritos.\n'
                            '• Controlar el inventario de tu botiquín y alertarte antes de que se agoten tus medicinas.\n'
                            '• Facilitar llamadas y mensajes directos a tus contactos de emergencia SOS.\n'
                            '• Generar tu informe médico en PDF para presentar a tu médico o especialista.',
                      ),
                      _seccion(
                        titulo: '4. Derechos del Titular (Derechos ARCO)',
                        texto: 'En cualquier momento tienes derecho a:\n'
                            '• Conocer, actualizar y rectificar tus datos personales.\n'
                            '• Solicitar prueba de la autorización otorgada.\n'
                            '• Ser informado respecto del uso que se le ha dado a tus datos.\n'
                            '• Revocar la autorización o solicitar la supresión de tus datos desde las opciones de tu Perfil.',
                      ),
                      _seccion(
                        titulo: '5. Seguridad y Confidencialidad',
                        texto: 'Tus datos están protegidos mediante estándares de seguridad digital: contraseñas cifradas con algoritmos irreversibles (bcrypt), tokens de sesión seguros y almacenamiento protegido. "Envejecer con Bienestar" NUNCA comercializará, venderá ni compartirá tus datos médicos con terceros con fines publicitarios.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Botón de Cierre ──
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Entendido y Cerrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion({required String titulo, required String texto}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}
