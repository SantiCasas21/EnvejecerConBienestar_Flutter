import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/actividad_cognitiva_model.dart';
import '../../domain/models/minijuego_definicion.dart';
import '../../domain/registry/minijuegos_registry.dart';
import '../providers/juegos_provider.dart';

class JuegosScreen extends ConsumerStatefulWidget {
  const JuegosScreen({super.key});

  @override
  ConsumerState<JuegosScreen> createState() => _JuegosScreenState();
}

class _JuegosScreenState extends ConsumerState<JuegosScreen> {
  int _tabPodioIndex = 0; // 0: Mis Récords (Consolidado), 1: Círculo Familiar
  String _filtroFamiliar = 'Todos';

  // Filtros temporales del historial
  int? _diasHistorial;
  bool _historialFamiliar = false;

  final List<String> _filtrosFamiliares = [
    'Todos',
    'Sudoku',
    'Buscar Pares',
    'Sopa de Letras',
    'Trivia de Cultura General',
    'Secuencia de Luces',
  ];

  final List<Map<String, dynamic>> _opcionesDias = [
    {'label': 'Todo', 'dias': null},
    {'label': '1 día', 'dias': 1},
    {'label': '3 días', 'dias': 3},
    {'label': '5 días', 'dias': 5},
    {'label': '8 días', 'dias': 8},
    {'label': '15 días', 'dias': 15},
    {'label': '30 días', 'dias': 30},
  ];

  String? _getFiltroFamiliarQuery(String f) {
    if (f == 'Todos') return null;
    return f;
  }

  void _refrescarDatos() {
    ref.invalidate(estadisticasJuegosProvider);
    ref.invalidate(puntosPorJuegoProvider);
    ref.invalidate(historialFiltradoProvider);
    ref.invalidate(historialJuegosProvider);
    ref.invalidate(podioFamiliarProvider);
  }

  @override
  Widget build(BuildContext context) {
    final estadisticasAsync = ref.watch(estadisticasJuegosProvider);
    final puntosPorJuegoAsync = ref.watch(puntosPorJuegoProvider);
    final podioFamiliarAsync = ref.watch(podioFamiliarProvider(_getFiltroFamiliarQuery(_filtroFamiliar)));

    final historialParams = HistorialParams(dias: _diasHistorial, familiar: _historialFamiliar);
    final historialFiltradoAsync = ref.watch(historialFiltradoProvider(historialParams));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Juegos y Estimulación',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar datos',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _refrescarDatos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refrescarDatos(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                'Ejercicios cognitivos diseñados para proteger la memoria, el razonamiento y la vitalidad diaria.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 16),

              // ── TARJETAS DE ESTADÍSTICAS DEL JUGADOR ──
              estadisticasAsync.when(
                data: (stats) => _buildEstadisticasCards(stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // ── LISTA DE MINIJUEGOS (DESDE MINIJUEGOSREGISTRY) ──
              const Text(
                'Elige un Juego para Empezar:',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ...MinijuegosRegistry.todos.map((juego) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2.5,
                  child: InkWell(
                    onTap: () => context.push(juego.ruta),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Fila superior: Badge de habilidad a la izquierda, rango de puntos a la derecha ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: juego.colorTema.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(juego.iconoHabilidad, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          juego.habilidadCognitiva,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: juego.colorTema,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                                ),
                                child: Text(
                                  '${juego.puntosPorNivel[NivelDificultad.basico]} - ${juego.puntosPorNivel[NivelDificultad.avanzado]} pts',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Fila principal: Icono (52dp), Título + Descripción, y Botón Jugar ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: juego.colorTema.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  juego.icono,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      juego.titulo,
                                      style: const TextStyle(
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      juego.descripcion,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: juego.colorTema,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: juego.colorTema.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 28),

              // ── SECCIÓN SALÓN DE LA FAMA (MIS RÉCORDS VS CÍRCULO FAMILIAR) ──
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Salón de la Fama y Clasificación',
                      style: TextStyle(
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
                'Compara tus mejores marcas acumuladas y el podio de competencia con tu familia:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // ── Toggle Segmentado de Alta Visibilidad ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tabPodioIndex = 0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabPodioIndex == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _tabPodioIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Mis Récords',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _tabPodioIndex == 0 ? AppColors.primaryTeal : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tabPodioIndex = 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabPodioIndex == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _tabPodioIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('👥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Círculo Familiar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _tabPodioIndex == 1 ? AppColors.primaryTeal : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Contenido de la Pestaña Activa ──
              if (_tabPodioIndex == 0) ...[
                // Pestaña 1: Mis Récords (Los 5 minijuegos ordenados por puntos acumulados)
                puntosPorJuegoAsync.when(
                  data: (lista) => _buildMisRecordsConsolidado(lista),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error al cargar récords: $err', style: const TextStyle(color: AppColors.emergencyRed)),
                  ),
                ),
              ] else ...[
                // Pestaña 2: Círculo Familiar (Con filtro por minijuego)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filtrosFamiliares.map((f) {
                      final isSelected = _filtroFamiliar == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            f,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: Colors.white,
                          onSelected: (val) {
                            if (val) setState(() => _filtroFamiliar = f);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                podioFamiliarAsync.when(
                  data: (resp) => _buildPodioFamiliarCards(resp),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error al cargar podio familiar: $err', style: const TextStyle(color: AppColors.emergencyRed)),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ── HISTORIAL RECIENTE CON SELECTOR TEMPORAL Y MODO FAMILIAR ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '📜 Historial de Partidas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(
                      _historialFamiliar ? Icons.groups_rounded : Icons.person_rounded,
                      size: 18,
                      color: _historialFamiliar ? Colors.white : AppColors.primaryTeal,
                    ),
                    label: Text(
                      _historialFamiliar ? 'Familia' : 'Solo yo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _historialFamiliar ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: _historialFamiliar,
                    selectedColor: AppColors.primaryTeal,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    onSelected: (val) => setState(() => _historialFamiliar = val),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Chips de Periodo de Días
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _opcionesDias.map((opc) {
                    final int? diasVal = opc['dias'] as int?;
                    final isSel = _diasHistorial == diasVal;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(
                          opc['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: AppColors.primaryTeal,
                        backgroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        onSelected: (val) {
                          if (val) setState(() => _diasHistorial = diasVal);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Lista de Partidas del Historial
              historialFiltradoAsync.when(
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
                      child: Column(
                        children: [
                          const Text('🎲', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            _diasHistorial != null
                                ? 'No hay partidas en los últimos $_diasHistorial días'
                                : 'Aún no hay partidas registradas',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '¡Elige un juego arriba para ejercitar tu mente y sumar puntos!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: historial.take(15).map((act) {
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
                            child: const Icon(Icons.star_rounded, color: AppColors.primaryTeal, size: 24),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  act.tipoJuego,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              if (_historialFamiliar)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: act.esUsuarioActual
                                        ? AppColors.primaryLight
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    act.nombreJugador,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: act.esUsuarioActual
                                          ? AppColors.primaryTeal
                                          : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${act.fechaFormateada} • Nivel ${act.nivelDificultad}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Text(
                            '+${act.puntaje} pts',
                            style: const TextStyle(
                              fontSize: 16,
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
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                ),
                error: (err, _) => Text('Error al cargar historial: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET: MIS RÉCORDS CONSOLIDADOS (1º A 5º CON COPAS Y MÁS JUGADO) ──
  Widget _buildMisRecordsConsolidado(List<PuntosPorJuegoModel> juegos) {
    if (juegos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Column(
          children: [
            Text('🏆', style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text(
              'Aún no tienes partidas registradas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: juegos.map((item) {
          Color borderColor;
          Color bgColor;
          Color accentColor;

          if (item.posicion == 1) {
            borderColor = const Color(0xFFFCD34D);
            bgColor = const Color(0xFFFEF3C7);
            accentColor = const Color(0xFFF59E0B);
          } else if (item.posicion == 2) {
            borderColor = const Color(0xFFCBD5E1);
            bgColor = const Color(0xFFF1F5F9);
            accentColor = const Color(0xFF64748B);
          } else if (item.posicion == 3) {
            borderColor = const Color(0xFFFDE68A);
            bgColor = const Color(0xFFFFFBEB);
            accentColor = const Color(0xFFB45309);
          } else {
            borderColor = AppColors.border;
            bgColor = Colors.white;
            accentColor = AppColors.textSecondary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                // Medalla o posición
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      item.medalla,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Info del juego
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.tipoJuego,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.esMasJugado) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ El más jugado',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '${item.partidasJugadas} partidas • Récord: ${item.recordMaximo} pts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Total de puntos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${item.totalPuntos} pts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── WIDGET: ESTADÍSTICAS TOTALES ──
  Widget _buildEstadisticasCards(EstadisticasJuegosModel stats) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], // Índigo Calma y Vitalidad
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.25),
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
                    Text('⭐', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Puntos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${stats.totalPuntos}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                    Text('🎮', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Partidas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${stats.partidasJugadas}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                    Text('👑', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Récord',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${stats.recordMaximo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── WIDGET: PODIO CÍRCULO FAMILIAR ──
  Widget _buildPodioFamiliarCards(PodioFamiliarRespuestaModel data) {
    if (data.podio.isEmpty || !data.hayVinculacion) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            const Text('👥', style: TextStyle(fontSize: 38)),
            const SizedBox(height: 8),
            const Text(
              '¡Compite y diviértete en familia!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vincula a tus cuidadores o familiares para comparar récords, compartir motivación y ejercitar juntos la memoria.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
            ),
            if (data.codigoVinculacionUsuario != null && data.codigoVinculacionUsuario!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryTeal, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Text(
                      'Código: ${data.codigoVinculacionUsuario}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primaryTeal),
                      tooltip: 'Copiar código',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: data.codigoVinculacionUsuario!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('¡Código de vinculación copiado al portapapeles!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: AppColors.primaryTeal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => context.push('/perfil'),
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Gestionar Cuidadores y Vínculos', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: AppColors.primaryTeal, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Podio de la Familia (${data.podio.length} jugadores)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          ...data.podio.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildPodioFamiliarFila(item),
              )),
        ],
      ),
    );
  }

  Widget _buildPodioFamiliarFila(PodioFamiliarItemModel item) {
    Color borderColor;
    Color bgColor;
    Color accentColor;

    if (item.posicion == 1) {
      borderColor = const Color(0xFFFCD34D);
      bgColor = const Color(0xFFFEF3C7);
      accentColor = const Color(0xFFF59E0B);
    } else if (item.posicion == 2) {
      borderColor = const Color(0xFFCBD5E1);
      bgColor = const Color(0xFFF1F5F9);
      accentColor = const Color(0xFF64748B);
    } else if (item.posicion == 3) {
      borderColor = const Color(0xFFFDE68A);
      bgColor = const Color(0xFFFFFBEB);
      accentColor = const Color(0xFFB45309);
    } else {
      borderColor = AppColors.border;
      bgColor = Colors.white;
      accentColor = AppColors.textSecondary;
    }

    if (item.esUsuarioActual) {
      borderColor = AppColors.primaryTeal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: item.esUsuarioActual ? 2.0 : 1.5),
      ),
      child: Row(
        children: [
          // Medalla o posición
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
            ),
            child: Center(
              child: Text(
                item.medalla,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Info del miembro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (item.esUsuarioActual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Tú',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.parentesco,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Puntaje acumulado destacado y récord
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.totalPuntos} pts',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.partidasJugadas} ${item.partidasJugadas == 1 ? "partida" : "partidas"} • Récord: ${item.puntajeMaximo} pts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
