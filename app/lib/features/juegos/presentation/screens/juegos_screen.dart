import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/actividad_cognitiva_model.dart';
import '../providers/juegos_provider.dart';

class JuegosScreen extends ConsumerStatefulWidget {
  const JuegosScreen({super.key});

  @override
  ConsumerState<JuegosScreen> createState() => _JuegosScreenState();
}

class _JuegosScreenState extends ConsumerState<JuegosScreen> {
  String _filtroPodio = 'Todos';

  final List<String> _filtros = [
    'Todos',
    'Sudoku',
    'Buscar Pares',
    'Ordenar Secuencia',
    'Sopa de Letras',
    'Trivia de Salud',
  ];

  @override
  Widget build(BuildContext context) {
    final estadisticasAsync = ref.watch(estadisticasJuegosProvider);
    final mejoresAsync = ref.watch(mejoresPuntajesProvider(_filtroPodio == 'Todos' ? null : _filtroPodio));
    final historialAsync = ref.watch(historialJuegosProvider);

    final juegos = [
      {
        'titulo': 'Sudoku Senior',
        'desc': 'Estimula tu lógica y concentración con cuadrículas 4x4, 6x6 y 9x9 adaptadas.',
        'icono': '🔢',
        'ruta': '/juegos/sudoku',
        'color': AppColors.primaryTeal,
      },
      {
        'titulo': 'Buscar Pares',
        'desc': 'Ejercita tu memoria visual encontrando parejas de cartas ilustradas.',
        'icono': '🧠',
        'ruta': '/juegos/buscar-pares',
        'color': AppColors.gamesViolet,
      },
      {
        'titulo': 'Ordenar Secuencia',
        'desc': 'Organiza paso a paso rutinas de autocuidado y salud diaria.',
        'icono': '📋',
        'ruta': '/juegos/ordenar-secuencia',
        'color': AppColors.primaryOrange,
      },
      {
        'titulo': 'Sopa de Letras',
        'desc': 'Descubre palabras clave para una vida sana y activa.',
        'icono': '🔤',
        'ruta': '/juegos/sopa-letras',
        'color': AppColors.healthGreen,
      },
      {
        'titulo': 'Trivia de Salud',
        'desc': 'Aprende y pon a prueba tus conocimientos sobre hábitos saludables.',
        'icono': '❓',
        'ruta': '/juegos/trivia',
        'color': AppColors.contactsBlue,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Juegos y Estimulación',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.gamesViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar puntajes',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: () {
              ref.invalidate(estadisticasJuegosProvider);
              ref.invalidate(mejoresPuntajesProvider);
              ref.invalidate(historialJuegosProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(estadisticasJuegosProvider);
          ref.invalidate(mejoresPuntajesProvider);
          ref.invalidate(historialJuegosProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ENCABEZADO ──
              const Text(
                '🎮 Gimnasio Mental',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ejercicios cognitivos diseñados para proteger la memoria, el razonamiento y la vitalidad.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 16),

              // ── TARJETAS DE ESTADÍSTICAS DEL JUGADOR ──
              estadisticasAsync.when(
                data: (stats) => _buildEstadisticasCards(stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: AppColors.gamesViolet),
                  ),
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // ── LISTA DE MINIJUEGOS ──
              const Text(
                'Elige un Juego para Empezar:',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ...juegos.map((j) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2.5,
                  child: InkWell(
                    onTap: () => context.push(j['ruta'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (j['color'] as Color).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              j['icono'] as String,
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  j['titulo'] as String,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  j['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: j['color'] as Color,
                            size: 38,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 28),

              // ── SECCIÓN SALÓN DE LA FAMA (PODIO TOP 1, 2 Y 3 CON COPITAS) ──
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Salón de la Fama y Mejores Puntajes',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tus récords más altos clasificados en el podio de campeones:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // ── Chips de Filtro por Minijuego ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filtros.map((f) {
                    final isSelected = _filtroPodio == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          f,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.gamesViolet,
                        backgroundColor: Colors.white,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filtroPodio = f);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // ── Podio Top 1, 2 y 3 ──
              mejoresAsync.when(
                data: (mejores) => _buildPodioCards(mejores),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.gamesViolet),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('Error al cargar podio: $err', style: const TextStyle(color: AppColors.emergencyRed)),
                ),
              ),
              const SizedBox(height: 28),

              // ── HISTORIAL RECIENTE DE PARTIDAS ──
              const Text(
                '📜 Historial Reciente de Partidas',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              historialAsync.when(
                data: (historial) {
                  if (historial.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Text('🎲', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 8),
                          Text(
                            'Aún no has jugado ninguna partida',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '¡Elige un juego arriba para ejercitar tu mente y sumar puntos!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: historial.take(8).map((act) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star_rounded, color: AppColors.gamesViolet, size: 24),
                          ),
                          title: Text(
                            act.tipoJuego,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            act.fechaFormateada,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          trailing: Text(
                            '+${act.puntaje} pts',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.healthGreen,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gamesViolet),
                ),
                error: (err, _) => Text('Error al cargar historial: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET: TARJETAS DE ESTADÍSTICAS TOTALES ──
  Widget _buildEstadisticasCards(EstadisticasJuegosModel stats) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('⭐', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Total Puntos',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.totalPuntos}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🎮', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Partidas',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.partidasJugadas}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('👑', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Récord',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.recordMaximo}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── WIDGET: PODIO TOP 1, 2 Y 3 CON COPITAS ──
  Widget _buildPodioCards(List<ActividadCognitiva> mejores) {
    if (mejores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.amber.shade50.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Aún no hay récords para $_filtroPodio',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '¡Juega tu primera partida para inaugurar este podio!',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final top1 = mejores.isNotEmpty ? mejores[0] : null;
    final top2 = mejores.length > 1 ? mejores[1] : null;
    final top3 = mejores.length > 2 ? mejores[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.amber.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (top1 != null)
            _buildPodioFila(
              posicion: 1,
              tituloPosicion: 'Top 1 - Campeón',
              emojiCopa: '🥇',
              colorCopa: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFEF3C7),
              borderColor: const Color(0xFFFCD34D),
              actividad: top1,
            ),
          if (top2 != null) ...[
            const SizedBox(height: 10),
            _buildPodioFila(
              posicion: 2,
              tituloPosicion: 'Top 2 - Plata',
              emojiCopa: '🥈',
              colorCopa: const Color(0xFF64748B),
              bgColor: const Color(0xFFF1F5F9),
              borderColor: const Color(0xFFCBD5E1),
              actividad: top2,
            ),
          ],
          if (top3 != null) ...[
            const SizedBox(height: 10),
            _buildPodioFila(
              posicion: 3,
              tituloPosicion: 'Top 3 - Bronce',
              emojiCopa: '🥉',
              colorCopa: const Color(0xFFB45309),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              actividad: top3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPodioFila({
    required int posicion,
    required String tituloPosicion,
    required String emojiCopa,
    required Color colorCopa,
    required Color bgColor,
    required Color borderColor,
    required ActividadCognitiva actividad,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          // Copa y posición
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: colorCopa, width: 2),
            ),
            child: Center(
              child: Text(
                emojiCopa,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Detalles del récord
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tituloPosicion,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: colorCopa,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${actividad.fechaFormateada}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  actividad.tipoJuego,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Puntaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorCopa.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${actividad.puntaje} pts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: colorCopa,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
