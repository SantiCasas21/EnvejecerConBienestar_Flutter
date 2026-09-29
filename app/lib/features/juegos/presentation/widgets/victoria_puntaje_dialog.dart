import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';

class VictoriaPuntajeDialog extends StatelessWidget {
  final String nombreJuego;
  final int puntaje;
  final String? mensajePersonalizado;
  final VoidCallback onJugarDeNuevo;
  final int? posicionTop; // 1, 2 o 3 si alcanzó podio

  const VictoriaPuntajeDialog({
    super.key,
    required this.nombreJuego,
    required this.puntaje,
    required this.onJugarDeNuevo,
    this.mensajePersonalizado,
    this.posicionTop,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required String nombreJuego,
    required int puntaje,
    required VoidCallback onJugarDeNuevo,
    String? mensajePersonalizado,
    int? posicionTop,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VictoriaPuntajeDialog(
        nombreJuego: nombreJuego,
        puntaje: puntaje,
        onJugarDeNuevo: onJugarDeNuevo,
        mensajePersonalizado: mensajePersonalizado,
        posicionTop: posicionTop,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ícono de Celebración o Copa ──
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: (posicionTop == 1)
                    ? const Color(0xFFFEF3C7) // Dorado suave
                    : AppColors.primaryLight.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (posicionTop == 1) ? const Color(0xFFF59E0B) : AppColors.primaryTeal,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  posicionTop == 1 ? '🏆' : posicionTop == 2 ? '🥈' : posicionTop == 3 ? '🥉' : '🎉',
                  style: const TextStyle(fontSize: 44),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Título ──
            const Text(
              '¡Excelente Trabajo!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completaste $nombreJuego',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // ── Tarjeta de Puntos Ganados ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.completedLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.healthGreen.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'PUNTOS GANADOS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      Text(
                        '+$puntaje',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.healthGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'pts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.healthGreen),
                      ),
                    ],
                  ),
                  if (posicionTop != null && posicionTop! >= 1 && posicionTop! <= 3) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade600),
                      ),
                      child: Text(
                        posicionTop == 1
                            ? '👑 ¡Nuevo Récord! Clasificado en Top 1'
                            : posicionTop == 2
                                ? '🥈 ¡Gran Partida! Clasificado en Top 2'
                                : '🥉 ¡Muy bien! Clasificado en Top 3',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Mensaje Pedagógico y de Bienestar ──
            Text(
              mensajePersonalizado ??
                  '¡Cada ejercicio mental estimula tu memoria, tu concentración y fortalece tu bienestar diario!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 24),

            // ── Botón Jugar de Nuevo ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onJugarDeNuevo();
                },
                icon: const Icon(Icons.replay_rounded, size: 22),
                label: const Text('Jugar de Nuevo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Botón Ir al Salón de Juegos ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/juegos');
                },
                icon: const Icon(Icons.emoji_events_outlined, size: 20, color: AppColors.gamesViolet),
                label: const Text('Ver Salón de Puntajes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gamesViolet)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gamesViolet, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
