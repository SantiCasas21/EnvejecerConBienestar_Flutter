import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/meta_model.dart';
import '../providers/metas_provider.dart';
import 'add_meta_dialog.dart';

/// Tarjeta interactiva, lúdica y accesible para el registro y seguimiento de hábitos de bienestar.
/// Diseñada con pautas de geriatría: elogios específicos por pilar, cronómetro de estiramientos,
/// ejercicios sugeridos guiados, y opciones completas de edición y eliminación.
class HabitoInteractivoCard extends ConsumerWidget {
  final MetaModel meta;

  const HabitoInteractivoCard({
    super.key,
    required this.meta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombreLower = meta.nombre.toLowerCase();

    if (nombreLower.contains('agua') || nombreLower.contains('hidrata')) {
      return _buildCardHidratacion(context, ref);
    } else if (nombreLower.contains('camin') || nombreLower.contains('paso') || nombreLower.contains('ejercicio')) {
      return _buildCardCaminata(context, ref);
    } else if (nombreLower.contains('sol') || nombreLower.contains('vitamina d')) {
      return _buildCardSol(context, ref);
    } else if (nombreLower.contains('estira') || nombreLower.contains('pausa') || nombreLower.contains('movilidad')) {
      return _buildCardEstiramientos(context, ref);
    } else if (nombreLower.contains('sueño') || nombreLower.contains('descanso') || nombreLower.contains('dormir')) {
      return _buildCardSueno(context, ref);
    } else if (nombreLower.contains('fruta') || nombreLower.contains('comida') || nombreLower.contains('nutri')) {
      return _buildCardNutricion(context, ref);
    } else if (nombreLower.contains('familiar') || nombreLower.contains('amigo') || nombreLower.contains('conversar')) {
      return _buildCardConexionFamiliar(context, ref);
    } else if (nombreLower.contains('mente') || nombreLower.contains('mental') || nombreLower.contains('memoria')) {
      return _buildCardGimnasioMental(context, ref);
    }

    return _buildCardGenerica(context, ref);
  }

  // ───────────────────────────────────────────────
  // 1. HIDRATACIÓN: 8 Vasitos Interactivos
  // ───────────────────────────────────────────────
  Widget _buildCardHidratacion(BuildContext context, WidgetRef ref) {
    final int vasosTomados = meta.progreso.clamp(0, meta.objetivo);
    final int vasosTotal = meta.objetivo > 0 ? meta.objetivo : 8;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '💧',
      titulo: 'Hidratación Vital',
      subtitulo: '$vasosTomados de $vasosTotal vasos tomados hoy',
      colorAcento: const Color(0xFF0284C7),
      colorFondoAcento: const Color(0xFFE0F2FE),
      completada: meta.completada || vasosTomados >= vasosTotal,
      elogioPersonalizado:
          '¡Excelente hidratación! Tus riñones, tu piel y tu cerebro funcionan al 100% gracias a ti. 💧',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Fila de vasitos interactivos
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(vasosTotal, (index) {
              final lleno = index < vasosTomados;
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (lleno && index == vasosTomados - 1) {
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: -1);
                  } else if (!lleno) {
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: 1);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 38,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lleno ? const Color(0xFF0284C7) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF0284C7),
                      width: 2,
                    ),
                    boxShadow: lleno
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    lleno ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                    color: lleno ? Colors.white : const Color(0xFF0284C7),
                    size: 24,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: 1);
              },
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text(
                'Tomar 1 Vaso de Agua',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 2. CAMINATA Y MOVIMIENTO ACTIVO
  // ───────────────────────────────────────────────
  Widget _buildCardCaminata(BuildContext context, WidgetRef ref) {
    return _TarjetaContenedorBase(
      meta: meta,
      icono: '🚶',
      titulo: 'Caminata y Movimiento Activo',
      subtitulo: '${meta.progreso} de ${meta.objetivo} minutos activos',
      colorAcento: AppColors.successGreen,
      colorFondoAcento: const Color(0xFFDCFCE7),
      completada: meta.completada,
      elogioPersonalizado:
          '¡Felicidades por cada paso! Tu corazón late con fuerza, mejoras tu equilibrio y llenas tu día de vitalidad. 🏃‍♂️',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: meta.porcentaje,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildBotonIncremento(
                  context,
                  ref,
                  label: '+10 min',
                  valor: 10,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBotonIncremento(
                  context,
                  ref,
                  label: '+15 min',
                  valor: 15,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBotonIncremento(
                  context,
                  ref,
                  label: '+30 min',
                  valor: 30,
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 3. BAÑO DE SOL Y VITAMINA D
  // ───────────────────────────────────────────────
  Widget _buildCardSol(BuildContext context, WidgetRef ref) {
    final bool yaTomoSol = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '☀️',
      titulo: 'Baño de Sol y Vitamina D',
      subtitulo: yaTomoSol
          ? '¡Baño de sol completado hoy! (15 minutos)'
          : '15 minutos de sol suave en brazos y rostro para fijar calcio',
      colorAcento: const Color(0xFFD97706),
      colorFondoAcento: const Color(0xFFFEF3C7),
      completada: yaTomoSol,
      elogioPersonalizado:
          '¡Qué buen sol recibiste! Tus huesos absorben el calcio y tu estado de ánimo se recarga de luz natural. ☀️',
      contenido: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                    meta.id,
                    valor: yaTomoSol ? -meta.objetivo : meta.objetivo,
                  );
            },
            icon: Icon(
              yaTomoSol ? Icons.wb_sunny_rounded : Icons.wb_sunny_outlined,
              size: 26,
            ),
            label: Text(
              yaTomoSol ? '✓ ¡Sol de Hoy Recibido!' : '¡Ya tomé mis 15 min de sol hoy!',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yaTomoSol ? const Color(0xFFD97706) : Colors.white,
              foregroundColor: yaTomoSol ? Colors.white : const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFD97706), width: 1.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: yaTomoSol ? 2 : 0,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 4. PAUSAS ACTIVAS Y ESTIRAMIENTOS (Con Cronómetro y Guía)
  // ───────────────────────────────────────────────
  Widget _buildCardEstiramientos(BuildContext context, WidgetRef ref) {
    final bool estirado = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '🧘',
      titulo: 'Pausas Activas y Estiramientos',
      subtitulo: '${meta.progreso} de ${meta.objetivo} minutos de movilidad hoy',
      colorAcento: AppColors.primaryTeal,
      colorFondoAcento: AppColors.primaryLight,
      completada: estirado,
      elogioPersonalizado:
          '¡Maravilloso estiramiento! Tus articulaciones y músculos están flexibles, previniendo rigidez y caídas. 🧘',
      contenido: _SeccionEstiramientosDetalle(
        meta: meta,
        estirado: estirado,
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 5. SUEÑO REPARADOR
  // ───────────────────────────────────────────────
  Widget _buildCardSueno(BuildContext context, WidgetRef ref) {
    final int estadoSueno = meta.progreso;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '😴',
      titulo: 'Sueño Reparador',
      subtitulo: estadoSueno > 0
          ? '¡Descanso nocturno registrado ($estadoSueno horas)!'
          : '¿Cómo sentiste tu descanso anoche?',
      colorAcento: const Color(0xFF4F46E5),
      colorFondoAcento: const Color(0xFFEEF2FF),
      completada: meta.completada || estadoSueno >= meta.objetivo,
      elogioPersonalizado:
          '¡Descanso reparador! Dormir en paz repara tus neuronas, fortalece tus defensas y te llena de vitalidad. 🌙',
      contenido: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: _buildBotonCarita(
                context,
                ref,
                emoji: '😊',
                texto: 'Muy Bien\n(7-8h)',
                isSelected: estadoSueno >= 7,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                        meta.id,
                        valor: 8 - meta.progreso,
                      );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBotonCarita(
                context,
                ref,
                emoji: '😐',
                texto: 'Regular\n(5-6h)',
                isSelected: estadoSueno >= 5 && estadoSueno < 7,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                        meta.id,
                        valor: 5 - meta.progreso,
                      );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBotonCarita(
                context,
                ref,
                emoji: '🥱',
                texto: 'Me Costó\n(< 5h)',
                isSelected: estadoSueno > 0 && estadoSueno < 5,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                        meta.id,
                        valor: 3 - meta.progreso,
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 6. ALIMENTACIÓN Y FRUTAS FRESCAS
  // ───────────────────────────────────────────────
  Widget _buildCardNutricion(BuildContext context, WidgetRef ref) {
    final int porciones = meta.progreso;
    final int total = meta.objetivo > 0 ? meta.objetivo : 3;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '🥗',
      titulo: 'Nutrición y Frutas Frescas',
      subtitulo: '$porciones de $total porciones consumidas hoy',
      colorAcento: const Color(0xFF16A34A),
      colorFondoAcento: const Color(0xFFF0FDF4),
      completada: meta.completada || porciones >= total,
      elogioPersonalizado:
          '¡Nutrición de oro! Tu sistema digestivo e inmunológico agradecen estas vitaminas y fibra fresca. 🍎',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildChipNutricion(
                  context,
                  ref,
                  label: '🍎 Fruta',
                  activo: porciones >= 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: porciones >= 1 ? -1 : 1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChipNutricion(
                  context,
                  ref,
                  label: '🥗 Verduras',
                  activo: porciones >= 2,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: porciones >= 2 ? -1 : 1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChipNutricion(
                  context,
                  ref,
                  label: '🍵 Cena Ligera',
                  activo: porciones >= 3,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: porciones >= 3 ? -1 : 1);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 7. CONEXIÓN FAMILIAR Y AFECTO
  // ───────────────────────────────────────────────
  Widget _buildCardConexionFamiliar(BuildContext context, WidgetRef ref) {
    final bool converso = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '📞',
      titulo: 'Afecto y Conexión Familiar',
      subtitulo: converso
          ? '¡Conversaste con tus seres queridos hoy!'
          : 'Llama o saluda a un hijo, nieto o amigo querido',
      colorAcento: const Color(0xFFDB2777),
      colorFondoAcento: const Color(0xFFFDF2F8),
      completada: converso,
      elogioPersonalizado:
          '¡El amor cura y alegra! Conversar con quienes quieres mantiene tu corazón contento y tu mente despierta. ❤️',
      contenido: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/contactos'),
                  icon: const Icon(Icons.contacts_rounded, size: 20),
                  label: const Text(
                    'Contactos',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDB2777),
                    side: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                          meta.id,
                          valor: converso ? -meta.objetivo : meta.objetivo,
                        );
                  },
                  icon: Icon(converso ? Icons.check_circle_rounded : Icons.favorite_rounded, size: 20),
                  label: Text(
                    converso ? '✓ ¡Ya conversé hoy!' : '¡Conversé con mi familia!',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: converso ? const Color(0xFFDB2777) : Colors.white,
                    foregroundColor: converso ? Colors.white : const Color(0xFFDB2777),
                    side: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: converso ? 2 : 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 8. GIMNASIO MENTAL Y MEMORIA
  // ───────────────────────────────────────────────
  Widget _buildCardGimnasioMental(BuildContext context, WidgetRef ref) {
    final bool ejercitado = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      meta: meta,
      icono: '🧠',
      titulo: 'Gimnasio Mental y Lectura',
      subtitulo: ejercitado
          ? '¡Tu mente estuvo activa y ejercitada hoy!'
          : 'Estimula tu memoria con un juego, lectura o crucigrama',
      colorAcento: AppColors.secondaryIndigo,
      colorFondoAcento: const Color(0xFFEEF2FF),
      completada: ejercitado,
      elogioPersonalizado:
          '¡Mente brillante! Mantienes tus neuronas activas, ágiles y lúcidas para recordar todo con claridad. 🧠',
      contenido: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/juegos'),
                  icon: const Icon(Icons.videogame_asset_rounded, size: 22),
                  label: const Text(
                    'Ir a Juegos',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                          meta.id,
                          valor: ejercitado ? -meta.objetivo : meta.objetivo,
                        );
                  },
                  icon: Icon(ejercitado ? Icons.check_circle_rounded : Icons.auto_stories_rounded, size: 20),
                  label: Text(
                    ejercitado ? '✓ ¡Leí o ejercité!' : 'Leí hoy',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryIndigo,
                    side: const BorderSide(color: AppColors.secondaryIndigo, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // CARD GENÉRICA PARA CUALQUIER HÁBITO PERSONALIZADO
  // ───────────────────────────────────────────────
  Widget _buildCardGenerica(BuildContext context, WidgetRef ref) {
    return _TarjetaContenedorBase(
      meta: meta,
      icono: meta.icono,
      titulo: meta.nombre,
      subtitulo: 'Progreso: ${meta.progreso} / ${meta.objetivo} ${meta.unidad}',
      colorAcento: AppColors.primaryTeal,
      colorFondoAcento: AppColors.primaryLight,
      completada: meta.completada,
      elogioPersonalizado:
          '¡Meta cumplida con éxito! La constancia diaria es el mayor regalo de salud y bienestar que te das. 🌟',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: meta.porcentaje,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                meta.completada ? AppColors.completed : AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: 1);
              },
              icon: const Icon(Icons.add_circle_rounded, size: 22),
              label: Text(
                'Registrar +1 ${meta.unidad}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // HELPERS DE BOTONES
  // ───────────────────────────────────────────────
  Widget _buildBotonIncremento(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int valor,
    required Color color,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id, valor: valor);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  Widget _buildBotonCarita(
    BuildContext context,
    WidgetRef ref, {
    required String emoji,
    required String texto,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF4F46E5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipNutricion(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF16A34A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF16A34A),
            width: activo ? 2 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: activo ? Colors.white : const Color(0xFF16A34A),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN EXPANDIBLE Y CRONÓMETRO DE ESTIRAMIENTOS
// ─────────────────────────────────────────────────────────────────────────────
class _SeccionEstiramientosDetalle extends ConsumerStatefulWidget {
  final MetaModel meta;
  final bool estirado;

  const _SeccionEstiramientosDetalle({
    required this.meta,
    required this.estirado,
  });

  @override
  ConsumerState<_SeccionEstiramientosDetalle> createState() => _SeccionEstiramientosDetalleState();
}

class _SeccionEstiramientosDetalleState extends ConsumerState<_SeccionEstiramientosDetalle> {
  bool _mostrarGuia = false;
  Timer? _timer;
  int _segundosTranscurridos = 0;
  bool _cronometroActivo = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarCronometro() {
    HapticFeedback.mediumImpact();
    setState(() {
      _cronometroActivo = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _segundosTranscurridos++;
        });
      }
    });
  }

  void _pausarCronometro() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _cronometroActivo = false;
    });
  }

  void _reiniciarCronometro() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _cronometroActivo = false;
      _segundosTranscurridos = 0;
    });
  }

  void _guardarTiempoEstiramiento() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();

    // Redondear a minutos: al menos 1 minuto si estiró >= 20 segundos
    final minutosCalculados = (_segundosTranscurridos >= 20)
        ? ((_segundosTranscurridos + 30) ~/ 60).clamp(1, 120)
        : 1;

    await ref.read(metasNotifierProvider.notifier).incrementarProgreso(
          widget.meta.id,
          valor: minutosCalculados,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 ¡Estupendo! Registraste $minutosCalculados min de estiramientos con tu cronómetro.',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _cronometroActivo = false;
        _segundosTranscurridos = 0;
      });
    }
  }

  String _formatearTiempo(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    final minStr = minutos.toString().padLeft(2, '0');
    final segStr = segundos.toString().padLeft(2, '0');
    return '$minStr:$segStr';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: widget.meta.porcentaje,
            minHeight: 12,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
        ),
        const SizedBox(height: 14),

        // ── Tarjeta de Cronómetro Interactivo ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.timer_outlined, color: AppColors.primaryTeal, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Cronómetro de Estiramiento',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  if (_cronometroActivo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EN CURSO',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Pantalla gigante del cronómetro
              Text(
                _formatearTiempo(_segundosTranscurridos),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                _cronometroActivo
                    ? '🧘 Respira profundo mientras estiras con calma...'
                    : (_segundosTranscurridos > 0
                        ? '⏸️ Cronómetro en pausa. Guarda para sumar tus minutos.'
                        : 'Toca iniciar para contabilizar tu sesión de estiramientos:'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Botones de acción del cronómetro
              if (!_cronometroActivo && _segundosTranscurridos == 0) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _iniciarCronometro,
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: const Text(
                      'Iniciar Cronómetro',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ] else if (_cronometroActivo) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _pausarCronometro,
                          icon: const Icon(Icons.pause_rounded, size: 22),
                          label: const Text(
                            'Pausar',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _guardarTiempoEstiramiento,
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: const Text(
                            'Guardar',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _iniciarCronometro,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'Reanudar',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryTeal,
                            side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _guardarTiempoEstiramiento,
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(
                            'Sumar +${((_segundosTranscurridos + 30) ~/ 60).clamp(1, 120)} min',
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Reiniciar',
                      onPressed: _reiniciarCronometro,
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Botón Colapsable de Guía de 4 Ejercicios Sugeridos ──
        InkWell(
          onTap: () {
            setState(() {
              _mostrarGuia = !_mostrarGuia;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ver 4 Ejercicios Suaves Sugeridos',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
                Icon(
                  _mostrarGuia ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFB45309),
                ),
              ],
            ),
          ),
        ),

        // ── Contenido de los 4 Ejercicios Sugeridos ──
        if (_mostrarGuia) ...[
          const SizedBox(height: 8),
          _buildItemEjercicio(
            icono: '🧘',
            nombre: '1. Cuello y Nuca Relajados',
            descripcion: 'Sentado derecho, inclina suavemente la cabeza hacia un hombro por 15 segundos. Respira hondo y cambia de lado.',
          ),
          _buildItemEjercicio(
            icono: '🔄',
            nombre: '2. Círculos con Hombros',
            descripcion: 'Mueve tus hombros en círculos lentos hacia atrás 5 veces y luego hacia adelante para soltar la espalda y el pecho.',
          ),
          _buildItemEjercicio(
            icono: '🦶',
            nombre: '3. Movilidad de Tobillos',
            descripcion: 'Sentado, eleva ligeramente un pie y gira el tobillo en círculos despacio. Favorece la circulación y previene caídas.',
          ),
          _buildItemEjercicio(
            icono: '✨',
            nombre: '4. Estrellas con las Manos',
            descripcion: 'Abre bien los dedos de tus manos como una estrella brillante y ciérralos en un puño suave 10 veces seguidas.',
          ),
        ],

        const SizedBox(height: 10),
        // Botón rápido de 1 toque (+5 min manuales)
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(metasNotifierProvider.notifier).incrementarProgreso(
                    widget.meta.id,
                    valor: widget.estirado ? -widget.meta.objetivo : 5,
                  );
            },
            icon: Icon(
              widget.estirado ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
              size: 20,
            ),
            label: Text(
              widget.estirado ? 'Restablecer meta de hoy' : '+5 min manuales (sin cronómetro)',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemEjercicio({
    required String icono,
    required String nombre,
    required String descripcion,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icono, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENEDOR BASE UNIFORME CON EDICIÓN, ELIMINACIÓN Y ELOGIOS
// ─────────────────────────────────────────────────────────────────────────────
class _TarjetaContenedorBase extends ConsumerWidget {
  final MetaModel meta;
  final String icono;
  final String titulo;
  final String subtitulo;
  final Color colorAcento;
  final Color colorFondoAcento;
  final bool completada;
  final String elogioPersonalizado;
  final Widget contenido;

  const _TarjetaContenedorBase({
    required this.meta,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorAcento,
    required this.colorFondoAcento,
    required this.completada,
    required this.elogioPersonalizado,
    required this.contenido,
  });

  void _abrirEditarMeta(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddMetaDialog(metaAEditar: meta),
    );

    if (!context.mounted) return;
    if (res != null) {
      await ref.read(metasNotifierProvider.notifier).updateMeta(meta.id, res);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Hábito "${res['nombre'] ?? meta.nombre}" actualizado con éxito.',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _confirmarEliminarMeta(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: AppColors.emergencyRed, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Eliminar Hábito',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar el hábito "${meta.nombre}" de tu rutina diaria?\n\nPodrás volver a agregarlo en cualquier momento.',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Sí, Eliminar',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirmar == true) {
      await ref.read(metasNotifierProvider.notifier).deleteMeta(meta.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hábito "${meta.nombre}" eliminado de tu día.',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: completada ? colorAcento.withValues(alpha: 0.6) : AppColors.border,
          width: completada ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorFondoAcento,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(icono, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (completada) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorAcento.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: colorAcento, size: 24),
                ),
                const SizedBox(width: 4),
              ],
              // Menú accesible de 3 puntos para Modificar / Eliminar
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22),
                tooltip: 'Opciones de hábito',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'editar') {
                    _abrirEditarMeta(context, ref);
                  } else if (val == 'eliminar') {
                    _confirmarEliminarMeta(context, ref);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: AppColors.primaryTeal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Modificar hábito',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.emergencyRed, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar hábito',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          contenido,
          // Banner de Elogio Clínico Personalizado al completar la meta
          if (completada) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorFondoAcento.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorAcento.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      elogioPersonalizado,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: colorAcento,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
