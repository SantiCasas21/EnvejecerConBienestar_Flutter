import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';

class ImcInfoDialog extends StatelessWidget {
  const ImcInfoDialog({super.key});

  static void mostrar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const ImcInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono y Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.accessibility_new_rounded, color: AppColors.primaryTeal, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '¿Qué es el IMC y por qué es importante?',
                      style: AppTypography.titulo().copyWith(
                        fontSize: 20,
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1.5, color: AppColors.border),

              // Explicación sencilla
              Text(
                'El Índice de Masa Corporal (IMC) es una medida médica internacional que relaciona tu peso con tu altura para evaluar si te encuentras en un rango corporal saludable.',
                style: AppTypography.cuerpo().copyWith(fontSize: 16),
              ),
              const SizedBox(height: 14),

              Text(
                '💡 ¿Por qué es fundamental conocerlo?',
                style: AppTypography.subtitulo().copyWith(
                  fontSize: 17,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Previene la sobrecarga en articulaciones y rodillas.\n• Protege tu salud cardiovascular y niveles de presión.\n• Evita la desnutrición o pérdida involuntaria de masa muscular (sarcopenia).',
                style: AppTypography.cuerpo().copyWith(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 18),

              // Rangos y Semáforo
              Text(
                '📊 Clasificación de Rangos:',
                style: AppTypography.subtitulo().copyWith(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildRangoItem(
                color: const Color(0xFFF97316),
                rango: 'Menos de 18.5 kg/m²',
                categoria: 'Bajo peso',
                descripcion: 'Recomendable consultar nutrición.',
              ),
              const SizedBox(height: 8),

              _buildRangoItem(
                color: const Color(0xFF22C55E),
                rango: '18.5 - 24.9 kg/m²',
                categoria: 'Peso saludable / Óptimo',
                descripcion: 'Excelente equilibrio y vitalidad.',
              ),
              const SizedBox(height: 8),

              _buildRangoItem(
                color: const Color(0xFFF97316),
                rango: '25.0 - 29.9 kg/m²',
                categoria: 'Sobrepeso',
                descripcion: 'Cuidar porciones y caminatas diarias.',
              ),
              const SizedBox(height: 8),

              _buildRangoItem(
                color: const Color(0xFFE11D48),
                rango: '30.0 kg/m² o más',
                categoria: 'Obesidad',
                descripcion: 'Seguimiento médico recomendado.',
              ),
              const SizedBox(height: 24),

              // Botón Entendido
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Entendido 👍', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangoItem({
    required Color color,
    required String rango,
    required String categoria,
    required String descripcion,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoria,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      rango,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
