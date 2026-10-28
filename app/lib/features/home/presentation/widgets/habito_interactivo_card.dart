import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/meta_model.dart';
import '../providers/metas_provider.dart';

/// Tarjeta interactiva y lúdica para el registro y seguimiento de hábitos de bienestar
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
      icono: '💧',
      titulo: 'Hidratación Vital',
      subtitulo: '$vasosTomados de $vasosTotal vasos tomados hoy',
      colorAcento: const Color(0xFF0284C7),
      colorFondoAcento: const Color(0xFFE0F2FE),
      completada: meta.completada || vasosTomados >= vasosTotal,
      mensajeExito: '¡Tu cuerpo y mente están hidratados y frescos! 💧',
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
                    // Si toca el último lleno, puede desmarcarlo
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
          // Botón ancho para sumar 1 vaso
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
  // 2. CAMINATA Y MOVIMIENTO: Botones de Suma Rápida
  // ───────────────────────────────────────────────
  Widget _buildCardCaminata(BuildContext context, WidgetRef ref) {
    return _TarjetaContenedorBase(
      icono: '🚶',
      titulo: 'Caminata y Movimiento Activo',
      subtitulo: '${meta.progreso} de ${meta.objetivo} minutos activos',
      colorAcento: AppColors.successGreen,
      colorFondoAcento: const Color(0xFFDCFCE7),
      completada: meta.completada,
      mensajeExito: '¡Tus piernas y corazón agradecen cada paso! 🌟',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Barra de progreso
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
          // Botones de incremento rápido
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
  // 3. BAÑO DE SOL Y VITAMINA D: Botón Dorado de 1 Toque
  // ───────────────────────────────────────────────
  Widget _buildCardSol(BuildContext context, WidgetRef ref) {
    final bool yaTomoSol = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      icono: '☀️',
      titulo: 'Baño de Sol y Vitamina D',
      subtitulo: yaTomoSol
          ? '¡Baño de sol completado hoy! (15 minutos)'
          : '15 minutos de sol suave en brazos y rostro para fijar calcio',
      colorAcento: const Color(0xFFD97706),
      colorFondoAcento: const Color(0xFFFEF3C7),
      completada: yaTomoSol,
      mensajeExito: '¡Huesos fortalecidos y ánimo revitalizado! ☀️',
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
  // 4. PAUSAS ACTIVAS Y ESTIRAMIENTOS
  // ───────────────────────────────────────────────
  Widget _buildCardEstiramientos(BuildContext context, WidgetRef ref) {
    final bool estirado = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      icono: '🧘',
      titulo: 'Pausas Activas y Estiramientos',
      subtitulo: estirado
          ? '¡Cuerpo estirado y articulaciones relajadas!'
          : 'Estiramientos suaves de cuello, hombros y tobillos',
      colorAcento: AppColors.primaryTeal,
      colorFondoAcento: AppColors.primaryLight,
      completada: estirado,
      mensajeExito: '¡Flexibilidad y articulaciones relajadas con amor! 🧘',
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
                    valor: estirado ? -meta.objetivo : meta.objetivo,
                  );
            },
            icon: Icon(
              estirado ? Icons.check_circle_rounded : Icons.self_improvement_rounded,
              size: 24,
            ),
            label: Text(
              estirado ? '✓ ¡Estiramientos Realizados!' : '¡Ya estiré mis articulaciones hoy!',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: estirado ? AppColors.primaryTeal : Colors.white,
              foregroundColor: estirado ? Colors.white : AppColors.primaryTeal,
              side: const BorderSide(color: AppColors.primaryTeal, width: 1.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: estirado ? 2 : 0,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // 5. SUEÑO REPARADOR: Caritas Táctiles
  // ───────────────────────────────────────────────
  Widget _buildCardSueno(BuildContext context, WidgetRef ref) {
    final int estadoSueno = meta.progreso; // 1: regular, 2: bien, 3: excelente

    return _TarjetaContenedorBase(
      icono: '😴',
      titulo: 'Sueño Reparador',
      subtitulo: estadoSueno > 0
          ? '¡Descanso nocturno registrado!'
          : '¿Cómo sentiste tu descanso anoche?',
      colorAcento: const Color(0xFF4F46E5),
      colorFondoAcento: const Color(0xFFEEF2FF),
      completada: meta.completada || estadoSueno >= meta.objetivo,
      mensajeExito: '¡Dormir en paz renueva tu energía y vitalidad! 🌙',
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
  // 6. ALIMENTACIÓN Y FRUTAS
  // ───────────────────────────────────────────────
  Widget _buildCardNutricion(BuildContext context, WidgetRef ref) {
    final int porciones = meta.progreso;
    final int total = meta.objetivo > 0 ? meta.objetivo : 3;

    return _TarjetaContenedorBase(
      icono: '🥗',
      titulo: 'Nutrición y Frutas Frescas',
      subtitulo: '$porciones de $total porciones consumidas hoy',
      colorAcento: const Color(0xFF16A34A),
      colorFondoAcento: const Color(0xFFF0FDF4),
      completada: meta.completada || porciones >= total,
      mensajeExito: '¡Alimentar tu cuerpo con frutas y vegetales te da vida! 🍎',
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
      icono: '📞',
      titulo: 'Afecto y Conexión Familiar',
      subtitulo: converso
          ? '¡Conversaste con tus seres queridos hoy!'
          : 'Llama o saluda a un hijo, nieto o amigo querido',
      colorAcento: const Color(0xFFDB2777),
      colorFondoAcento: const Color(0xFFFDF2F8),
      completada: converso,
      mensajeExito: '¡El amor y las charlas alegran el alma y el corazón! ❤️',
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
                    'Ver Contactos',
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
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800),
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
  // 8. GIMNASIO MENTAL
  // ───────────────────────────────────────────────
  Widget _buildCardGimnasioMental(BuildContext context, WidgetRef ref) {
    final bool ejercitado = meta.completada || meta.progreso >= meta.objetivo;

    return _TarjetaContenedorBase(
      icono: '🧠',
      titulo: 'Gimnasio Mental y Lectura',
      subtitulo: ejercitado
          ? '¡Tu mente estuvo activa y ejercitada hoy!'
          : 'Estimula tu memoria con un juego, lectura o crucigrama',
      colorAcento: AppColors.secondaryIndigo,
      colorFondoAcento: const Color(0xFFEEF2FF),
      completada: ejercitado,
      mensajeExito: '¡Tu cerebro es un músculo vivo que se fortalece! 🧠',
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
      icono: meta.icono,
      titulo: meta.nombre,
      subtitulo: 'Progreso: ${meta.progreso} / ${meta.objetivo} ${meta.unidad}',
      colorAcento: AppColors.primaryTeal,
      colorFondoAcento: AppColors.primaryLight,
      completada: meta.completada,
      mensajeExito: meta.obtenerMensajeMotivacional(),
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

/// Contenedor base uniforme con diseño senior y accesible
class _TarjetaContenedorBase extends StatelessWidget {
  final String icono;
  final String titulo;
  final String subtitulo;
  final Color colorAcento;
  final Color colorFondoAcento;
  final bool completada;
  final String mensajeExito;
  final Widget contenido;

  const _TarjetaContenedorBase({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorAcento,
    required this.colorFondoAcento,
    required this.completada,
    required this.mensajeExito,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
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
              if (completada)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorAcento.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: colorAcento, size: 24),
                ),
            ],
          ),
          contenido,
          if (completada) ...[
            const SizedBox(height: 10),
            Text(
              mensajeExito,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: colorAcento,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
