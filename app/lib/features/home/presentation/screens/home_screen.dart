import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/bienvenida_dialog.dart';
import '../../../contactos/presentation/providers/contactos_provider.dart';
import '../../../medicamentos/presentation/providers/medicamentos_provider.dart';
import '../../../perfil/data/models/perfil_model.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../data/models/meta_model.dart';
import '../providers/metas_provider.dart';
import '../widgets/add_meta_dialog.dart';
import '../widgets/habito_interactivo_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingRevisado = false;
  int _tabSeleccionada = 0; // 0: Mi Día y Salud, 1: Hábitos de Bienestar

  static const List<Map<String, dynamic>> _catalogoPilares = [
    {
      'clave': 'agua',
      'nombre': 'Tomar agua',
      'objetivo': 8,
      'unidad': 'vasos',
      'icono': '💧',
      'descripcion': '8 vasitos de agua al día para mantenerte hidratado y con energía.',
      'color': Color(0xFF0284C7),
    },
    {
      'clave': 'camin',
      'nombre': 'Caminata y paseo',
      'objetivo': 30,
      'unidad': 'minutos',
      'icono': '🚶',
      'descripcion': '30 minutos para activar tus articulaciones y tu corazón.',
      'color': Color(0xFF059669),
    },
    {
      'clave': 'sol',
      'nombre': 'Sol y Vitamina D',
      'objetivo': 15,
      'unidad': 'minutos',
      'icono': '☀️',
      'descripcion': '15 minutos de sol de la mañana para tus defensas y huesos.',
      'color': Color(0xFFD97706),
    },
    {
      'clave': 'estira',
      'nombre': 'Estiramientos suaves',
      'objetivo': 10,
      'unidad': 'minutos',
      'icono': '🧘',
      'descripcion': '10 minutos de movilidad para relajar cuello, espalda y piernas.',
      'color': Color(0xFF4F46E5),
    },
    {
      'clave': 'sueño',
      'nombre': 'Sueño reparador',
      'objetivo': 8,
      'unidad': 'horas',
      'icono': '😴',
      'descripcion': 'Descanso nocturno profundo y tranquilo.',
      'color': Color(0xFF6366F1),
    },
    {
      'clave': 'nutri',
      'nombre': 'Fruta y verdura',
      'objetivo': 3,
      'unidad': 'porciones',
      'icono': '🥗',
      'descripcion': '3 porciones saludables para nutrir tu organismo.',
      'color': Color(0xFF16A34A),
    },
    {
      'clave': 'familiar',
      'nombre': 'Llamada familiar',
      'objetivo': 1,
      'unidad': 'charla',
      'icono': '📞',
      'descripcion': '1 charla o llamada con un familiar o amigo especial.',
      'color': Color(0xFFE11D48),
    },
    {
      'clave': 'mente',
      'nombre': 'Gimnasio mental',
      'objetivo': 15,
      'unidad': 'minutos',
      'icono': '🧠',
      'descripcion': '15 minutos ejercitando la mente con pasatiempos y juegos.',
      'color': Color(0xFF9333EA),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarOnboardingPrimerInicio();
    });
  }

  void _verificarOnboardingPrimerInicio() async {
    if (_onboardingRevisado || !mounted) return;
    _onboardingRevisado = true;

    final user = ref.read(authNotifierProvider).user;
    if (user == null || user.esCuidador) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'onboarding_adulto_mayor_${user.id}';
    final yaVisto = prefs.getBool(key) ?? false;

    if (!yaVisto && mounted) {
      await prefs.setBool(key, true);
      if (!mounted) return;
      final nuevoPerfil = await showDialog<PerfilModel>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BienvenidaDialog(initialNombre: user.nombre),
      );

      if (nuevoPerfil != null && mounted) {
        ref.read(perfilNotifierProvider.notifier).actualizarPerfil(nuevoPerfil);
      }
    }
  }

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return '☀️ ¡Buenos días';
    } else if (hora >= 12 && hora < 19) {
      return '🌤️ ¡Buenas tardes';
    } else {
      return '🌙 ¡Buenas noches';
    }
  }

  String _formatearFechaHoy() {
    final ahora = DateTime.now();
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final diaSemana = dias[ahora.weekday - 1];
    final mes = meses[ahora.month - 1];
    return '$diaSemana, ${ahora.day} de $mes';
  }

  void _llamarSOS(BuildContext context, WidgetRef ref) async {
    final contactosAsync = ref.read(contactosNotifierProvider);
    final contactos = contactosAsync.value ?? [];
    final perfil = ref.read(perfilNotifierProvider).value;

    String? telefonoSOS = perfil?.contactoEmergenciaTelefono;
    String? nombreSOS = perfil?.contactoEmergenciaNombre;
    if (telefonoSOS == null || telefonoSOS.isEmpty) {
      final sos = contactos.where((c) => c.esEmergencia).firstOrNull;
      telefonoSOS = sos?.telefono;
      nombreSOS ??= sos?.nombre;
    }

    await CallService.iniciarSosConRespaldo(
      context,
      telefonoContacto: telefonoSOS,
      nombreContacto: nombreSOS,
    );
  }

  void _abrirAddMeta(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddMetaDialog(),
    );

    if (result != null) {
      await ref.read(metasNotifierProvider.notifier).addMeta(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌿 Hábito "${result['nombre']}" agregado con éxito.',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _agregarHabitoRecomendado(BuildContext context, Map<String, dynamic> sugerencia) async {
    HapticFeedback.mediumImpact();
    await ref.read(metasNotifierProvider.notifier).addMeta({
      'nombre': sugerencia['nombre'],
      'objetivo': sugerencia['objetivo'],
      'progreso': 0,
      'unidad': sugerencia['unidad'],
      'icono': sugerencia['icono'],
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🌿 ¡${sugerencia['nombre']} agregado a tus hábitos diarios!',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final perfilAsync = ref.watch(perfilNotifierProvider);
    final medicamentosAsync = ref.watch(medicamentosNotifierProvider);
    final metasAsync = ref.watch(metasNotifierProvider);

    final nombreUsuario = authState.user?.nombre ?? 'Amigo/a';
    final perfil = perfilAsync.value;
    final estaCompleto = perfil?.estaCompleto ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: () async {
            ref.invalidate(medicamentosNotifierProvider);
            ref.invalidate(metasNotifierProvider);
            ref.invalidate(perfilNotifierProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Encabezado de Saludo Dinámico con Fecha ──
                Text(
                  '${_obtenerSaludo()}, $nombreUsuario!',
                  style: AppTypography.titulo().copyWith(
                    fontSize: 26,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatearFechaHoy(),
                        style: AppTypography.cuerpo().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Selector Segmentado Superior: Mi Día y Salud vs Hábitos de Bienestar ──
                _buildSelectorPestanas(),
                const SizedBox(height: 16),

                // ── Contenido según pestaña activa ──
                if (_tabSeleccionada == 0) ...[
                  _buildVistaMiDiaYSalud(
                    context: context,
                    perfil: perfil,
                    estaCompleto: estaCompleto,
                    medicamentosAsync: medicamentosAsync,
                    metasAsync: metasAsync,
                  ),
                ] else ...[
                  _buildVistaHabitosBienestar(
                    context: context,
                    metasAsync: metasAsync,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTOR SEGMENTADO (PILL TABS)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSelectorPestanas() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBotonPestana(
              index: 0,
              icono: Icons.wb_sunny_rounded,
              titulo: 'Mi Día y Salud',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildBotonPestana(
              index: 1,
              icono: Icons.eco_rounded,
              titulo: 'Hábitos Vitales',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPestana({
    required int index,
    required IconData icono,
    required String titulo,
  }) {
    final activo = _tabSeleccionada == index;
    return InkWell(
      onTap: () {
        if (!activo) {
          HapticFeedback.selectionClick();
          setState(() => _tabSeleccionada = index);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 20,
              color: activo ? AppColors.primaryTeal : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                  color: activo ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PESTAÑA 0: MI DÍA Y SALUD (Salud clínica, SOS, Próxima Dosis, Juegos, Resumen)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVistaMiDiaYSalud({
    required BuildContext context,
    required PerfilModel? perfil,
    required bool estaCompleto,
    required AsyncValue medicamentosAsync,
    required AsyncValue<List<MetaModel>> metasAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner de Ficha Médica Incompleta
        if (!estaCompleto) ...[
          InkWell(
            onTap: () => context.push('/perfil/editar'),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryTeal, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryTeal, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu Ficha Médica está al ${perfil?.porcentajeCompletitudEntero ?? 0}%',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Toca aquí para completarla y registrar tus contactos de urgencia.',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.primaryTeal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Botón SOS Prominente (72dp de alto, Rojo Carmesí)
        SizedBox(
          width: double.infinity,
          height: 72,
          child: ElevatedButton.icon(
            onPressed: () => _llamarSOS(context, ref),
            icon: const Icon(Icons.sos_rounded, size: 40, color: Colors.white),
            label: const Text(
              'BOTÓN SOS DE EMERGENCIA',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sección Medicinas de Hoy
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '💊 Medicinas de Hoy',
                style: AppTypography.subtitulo().copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/medicamentos'),
              icon: const Icon(Icons.list_alt_rounded, size: 18, color: AppColors.primaryTeal),
              label: const Text(
                'Ver todas',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildSeccionMedicamentos(medicamentosAsync),
        const SizedBox(height: 24),

        // Tarjeta Destacada: Gimnasio Mental y Salón de la Fama
        InkWell(
          onTap: () => context.go('/juegos'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🧠', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gimnasio Mental y Juegos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Sudoku, Buscar Pares, Sopa y Salón de la Fama 🏆',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Mini Resumen de Hábitos del Día
        _buildResumenHabitosHoy(metasAsync),
        const SizedBox(height: 20),

        // Acceso directo al Asistente de Salud IA (Módulo 9)
        InkWell(
          onTap: () => context.push('/asistente'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryTeal,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.primaryTeal,
                    size: 26,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente de Salud IA',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Revisa alergias, medicinas o prepara tu cita',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFFCCFBF1),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Acceso directo al Historial
        InkWell(
          onTap: () => context.push('/historial'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.primaryTeal, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ver Historial de Tomas y Adherencia Pasada',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryTeal),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEDICAMENTOS DE HOY
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSeccionMedicamentos(AsyncValue medicamentosAsync) {
    return medicamentosAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
      error: (err, _) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error al cargar medicinas: $err', style: AppTypography.cuerpo()),
        ),
      ),
      data: (medicamentos) {
        if (medicamentos == null || (medicamentos as List).isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No tienes medicamentos programados para hoy.',
                      style: AppTypography.cuerpo().copyWith(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final pendientes = medicamentos.where((m) => !(m.estaTomado ?? false)).toList();

        if (pendientes.isNotEmpty) {
          final proximo = pendientes.first;
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryTeal, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✨ Próxima dosis pendiente',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(proximo.icono, style: const TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proximo.nombre,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${proximo.miligramos ?? ""} • Cada ${proximo.frecuencia ?? 8} horas',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(medicamentosNotifierProvider.notifier).toggleTomado(proximo.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.healthGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(96, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Tomar',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Card(
          color: const Color(0xFFF0FDF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18.0),
            child: Row(
              children: [
                Text('✅', style: TextStyle(fontSize: 30)),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '¡Excelente trabajo! Has completado todas tus medicinas programadas para hoy.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MINI RESUMEN DE HÁBITOS EN LA PESTAÑA PRINCIPAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildResumenHabitosHoy(AsyncValue<List<MetaModel>> metasAsync) {
    return metasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (metas) {
        final total = metas.length;
        final completadas = metas.where((m) => m.completada || m.porcentaje >= 1.0).length;
        final ratio = total > 0 ? (completadas / total) : 0.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🌿', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hábitos de Hoy',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      total == 0 ? 'Sin hábitos' : '$completadas de $total listos',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _tabSeleccionada = 1);
                  },
                  icon: const Icon(Icons.touch_app_rounded, color: AppColors.primaryTeal, size: 20),
                  label: const Text(
                    'Explorar y Registrar Mis Hábitos ➔',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PESTAÑA 1: HÁBITOS DE BIENESTAR (Catálogo interactivo de 8 pilares)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVistaHabitosBienestar({
    required BuildContext context,
    required AsyncValue<List<MetaModel>> metasAsync,
  }) {
    return metasAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
      error: (err, _) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error al cargar hábitos: $err', style: AppTypography.cuerpo()),
        ),
      ),
      data: (metas) {
        final total = metas.length;
        final completadas = metas.where((m) => m.completada || m.porcentaje >= 1.0).length;
        final porcentajeGlobal = total > 0 ? (completadas / total) : 0.0;

        // Comprobamos qué pilares de los 8 aún no tiene agregados
        final sugerenciasFaltantes = _catalogoPilares.where((sug) {
          final clave = sug['clave'] as String;
          return !metas.any((m) => m.nombre.toLowerCase().contains(clave));
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medidor Global de Adherencia Diaria
            _buildMedidorAdherencia(
              total: total,
              completadas: completadas,
              porcentaje: porcentajeGlobal,
            ),
            const SizedBox(height: 20),

            // Encabezado de la lista activa
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '🌱 Mis Hábitos Activos',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _abrirAddMeta(context, ref),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryTeal, size: 20),
                  label: const Text(
                    'Crear Hábito',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de tarjetas interactivas activas
            if (metas.isEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 10),
                      const Text(
                        '¡Inicia hoy con tus hábitos saludables!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Selecciona alguna de las sugerencias recomendadas abajo para comenzar a registrar tu día con 1 solo toque.',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _abrirAddMeta(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Personalizar Mi Primer Hábito',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...metas.map((meta) => HabitoInteractivoCard(meta: meta)),
            ],
            const SizedBox(height: 24),

            // Catálogo de hábitos recomendados que aún no tiene
            if (sugerenciasFaltantes.isNotEmpty) ...[
              const Text(
                '💡 Hábitos Recomendados para tu Bienestar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Agrega con 1 toque pilares clave de la geriatría moderna:',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...sugerenciasFaltantes.take(4).map((sug) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (sug['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(sug['icono'] as String, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sug['nombre'] as String,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              '${sug['objetivo']} ${sug['unidad']} al día',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _agregarHabitoRecomendado(context, sug),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: AppColors.primaryTeal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          '➕ Agregar',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Botón ancho para abrir el modal de personalización
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _abrirAddMeta(context, ref),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                label: const Text(
                  'Crear Hábito Personalizado',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Enlace a Historial de Días Anteriores
            InkWell(
              onTap: () => context.push('/historial'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.primaryTeal, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ver Historial de Hábitos en el Calendario',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryTeal),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEDIDOR DE ADHERENCIA GLOBAL DE HÁBITOS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMedidorAdherencia({
    required int total,
    required int completadas,
    required double porcentaje,
  }) {
    String mensaje;
    if (total == 0) {
      mensaje = 'Comienza hoy agregando tu primer hábito saludable 🌱';
    } else if (completadas == total) {
      mensaje = '🎉 ¡Increíble! Has cumplido todos tus hábitos diarios de hoy.';
    } else if (completadas > 0) {
      mensaje = '💪 ¡Gran progreso! Llevas $completadas de $total hábitos completados.';
    } else {
      mensaje = '☀️ Cada pequeño paso de hoy suma vitalidad y salud a tu vida.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Vitalidad y Hábitos Diarios',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(porcentaje * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? porcentaje : 0.0,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
