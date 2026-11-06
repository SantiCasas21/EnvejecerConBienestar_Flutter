import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../historial/data/models/racha_model.dart';
import '../../../historial/presentation/providers/racha_provider.dart';

/// Widget de Racha Fueguito interactivo (estilo Duolingo / TikTok) para HomeScreen
class RachaFuegoWidget extends ConsumerStatefulWidget {
  const RachaFuegoWidget({super.key});

  @override
  ConsumerState<RachaFuegoWidget> createState() => _RachaFuegoWidgetState();
}

class _RachaFuegoWidgetState extends ConsumerState<RachaFuegoWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Evitar animación infinita durante pruebas unitarias para no bloquear pumpAndSettle
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      _animController.repeat(reverse: true);
    }

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _abrirDialogoRacha(BuildContext context, RachaModel racha) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => _RachaInfoDialog(racha: racha),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.value ??
        const RachaModel(
          usuarioId: 1,
          rachaActual: 0,
          rachaMejor: 0,
          mensajeRacha: '¡Enciende tu llama de bienestar hoy! 🔥',
        );

    final tieneRacha = racha.rachaActual > 0;

    return InkWell(
      onTap: () => _abrirDialogoRacha(context, racha),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: tieneRacha
              ? const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: tieneRacha
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
          border: Border.all(
            color: tieneRacha ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
            width: tieneRacha ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: tieneRacha ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
              child: const Text('🔥', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 6),
            Text(
              '${racha.rachaActual} ${racha.rachaActual == 1 ? "Día" : "Días"}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: tieneRacha ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RachaInfoDialog extends StatelessWidget {
  final RachaModel racha;

  const _RachaInfoDialog({required this.racha});

  @override
  Widget build(BuildContext context) {
    final tieneRacha = racha.rachaActual > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fueguito central con aureola dorada
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFEF08A), Color(0xFFFED7AA), Colors.transparent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔥', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 12),

              // Contador de racha
              Text(
                '${racha.rachaActual} ${racha.rachaActual == 1 ? "Día de Racha" : "Días de Racha"}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFC2410C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                racha.mensajeRacha,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Calendario semanal L M M J V S D con estados
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tu semana de constancia:',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: (racha.diasSemana.isNotEmpty
                              ? racha.diasSemana
                              : [
                                  DiaSemanaRacha(letra: 'L', fecha: '', activo: tieneRacha, esHoy: false),
                                  DiaSemanaRacha(letra: 'M', fecha: '', activo: tieneRacha, esHoy: false),
                                  DiaSemanaRacha(letra: 'M', fecha: '', activo: tieneRacha, esHoy: true),
                                  DiaSemanaRacha(letra: 'J', fecha: '', activo: false, esHoy: false),
                                  DiaSemanaRacha(letra: 'V', fecha: '', activo: false, esHoy: false),
                                  DiaSemanaRacha(letra: 'S', fecha: '', activo: false, esHoy: false),
                                  DiaSemanaRacha(letra: 'D', fecha: '', activo: false, esHoy: false),
                                ])
                          .map((dia) {
                        return Column(
                          children: [
                            Text(
                              dia.letra,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dia.esHoy ? const Color(0xFFC2410C) : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: dia.activo
                                    ? const Color(0xFFEA580C)
                                    : (dia.esHoy ? const Color(0xFFFED7AA) : Colors.white),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: dia.activo
                                      ? const Color(0xFFEA580C)
                                      : (dia.esHoy ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1)),
                                  width: dia.esHoy ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: dia.activo
                                  ? const Text('🔥', style: TextStyle(fontSize: 16))
                                  : (dia.esHoy
                                      ? const Icon(Icons.star_rounded, size: 18, color: Color(0xFFEA580C))
                                      : const SizedBox.shrink()),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Nota de salud y cero culpa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu cuerpo valora cada día de cuidado. Cumple tus medicinas o un hábito para mantener encendida tu llama.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón de cierre
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '¡A seguir cuidándome!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
