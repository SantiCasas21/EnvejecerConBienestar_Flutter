import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../../core/utils/pdf_report_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/metas_provider.dart';
import '../../../medicamentos/presentation/providers/medicamentos_provider.dart';
import '../../../medicamentos/presentation/providers/tratamientos_provider.dart';
import '../providers/perfil_provider.dart';
import '../widgets/habeas_data_dialog.dart';
import '../widgets/imc_info_dialog.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _generandoPdf = false;

  void _exportarReportePdf() async {
    final authUser = ref.read(authNotifierProvider).user;
    if (authUser == null) return;

    setState(() => _generandoPdf = true);

    try {
      final perfil = await ref.read(perfilNotifierProvider.future);
      final medicamentos = ref.read(medicamentosNotifierProvider).value ?? [];
      final metas = ref.read(metasNotifierProvider).value ?? [];

      await PdfReportService.generarYCompartirReporte(
        usuario: authUser,
        perfil: perfil,
        medicamentos: medicamentos,
        metas: metas,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('¿Cerrar Sesión?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
            ),
            child: const Text('Sí, salir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final perfilAsync = ref.watch(perfilNotifierProvider);
    final userName = authState.user?.nombre ?? 'Usuario';
    final userEmail = authState.user?.email ?? '';

    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '👤';
    final avatarBgColor = AppColors.generarColorPorNombre(userName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil de Salud',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            tooltip: 'Editar Ficha Médica',
            icon: const Icon(Icons.edit_note_rounded, size: 34),
            onPressed: () => context.push('/perfil/editar'),
          ),
        ],
      ),
      body: perfilAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
        error: (err, stack) => Center(
          child: Text('Error al cargar perfil: $err', style: AppTypography.cuerpo()),
        ),
        data: (perfil) {
          final estaCompleto = perfil?.estaCompleto ?? false;
          final porcentaje = perfil?.porcentajeCompletitud ?? 0.0;
          final porcentajeEntero = perfil?.porcentajeCompletitudEntero ?? 0;
          final faltantes = perfil?.camposFaltantes ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── BARRA DE PROGRESO DE COMPLETITUD DINÁMICA ──
                // Si la ficha no está al 100%, mostramos esta tarjeta; al llegar al 100% se oculta automáticamente.
                if (!estaCompleto) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.primaryTeal, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('📋', style: TextStyle(fontSize: 26)),
                                const SizedBox(width: 8),
                                Text(
                                  'Ficha Médica: $porcentajeEntero% Completa',
                                  style: AppTypography.subtitulo().copyWith(
                                    color: AppColors.primaryDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: porcentaje,
                            minHeight: 14,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              porcentajeEntero < 50 ? AppColors.emergencyRed : AppColors.primaryTeal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Te recomendamos completar tu información para emergencias y reportes médicos.',
                          style: AppTypography.pequeno().copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        if (faltantes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: faltantes.map((f) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  '+ $f',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/perfil/editar'),
                            icon: const Icon(Icons.edit_note_rounded, size: 24),
                            label: const Text('Completar Ficha Médica Ahora', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── CABECERA: AVATAR Y DATOS DEL USUARIO ──
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: avatarBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryTeal, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: AppTypography.titulo().copyWith(
                    fontSize: 26,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    textAlign: TextAlign.center,
                    style: AppTypography.pequeno().copyWith(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 10),

                // Badge de Estado de Ficha
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: estaCompleto ? AppColors.completedLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: estaCompleto ? AppColors.healthGreen : AppColors.primaryTeal),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estaCompleto ? Icons.verified_rounded : Icons.health_and_safety_rounded,
                          size: 20,
                          color: estaCompleto ? AppColors.completed : AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          estaCompleto ? 'Ficha Médica 100% Completa' : 'Ficha Médica en Progreso ($porcentajeEntero%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: estaCompleto ? AppColors.primaryDark : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── BOTONES DE ACCIÓN PRINCIPALES ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generandoPdf ? null : _exportarReportePdf,
                        icon: _generandoPdf 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf_rounded, size: 22),
                        label: const Text('Exportar PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/perfil/editar'),
                        icon: const Icon(Icons.edit_rounded, size: 22, color: AppColors.primaryTeal),
                        label: const Text('Modificar Ficha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.cardBackground,
                          side: const BorderSide(color: AppColors.primaryTeal, width: 2),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── TARJETA 1: DATOS VITALES Y BIOMETRÍA ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('📋', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Text(
                                  'Datos Vitales e Identidad',
                                  style: AppTypography.subtitulo().copyWith(
                                    color: AppColors.primaryTeal,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                        _buildItemVisual(
                          icono: Icons.cake_outlined,
                          titulo: 'Fecha de Nacimiento / Cumpleaños',
                          valor: perfil?.fechaNacimiento?.isNotEmpty == true 
                              ? perfil!.fechaNacimiento! 
                              : 'No especificada',
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.calendar_today_outlined,
                                titulo: 'Edad',
                                valor: perfil?.textoEdad ?? 'No especificada',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.bloodtype_outlined,
                                titulo: 'Tipo de Sangre',
                                valor: perfil?.tipoSangre ?? 'O+',
                                valorColor: AppColors.emergencyRed,
                                destacarValor: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.person_outline,
                                titulo: 'Género',
                                valor: perfil?.genero ?? 'No especificado',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.health_and_safety_outlined,
                                titulo: 'EPS / Seguro',
                                valor: perfil?.eps ?? 'No especificada',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.monitor_weight_outlined,
                                titulo: 'Peso',
                                valor: perfil?.peso != null ? '${perfil!.peso} kg' : 'Sin registrar',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.height_outlined,
                                titulo: 'Altura',
                                valor: perfil?.altura != null ? '${perfil!.altura} cm' : 'Sin registrar',
                              ),
                            ),
                          ],
                        ),

                        // Indicador Visual de IMC
                        if (perfil?.imc != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: perfil!.colorImc.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: perfil.colorImc, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: perfil.colorImc,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Índice de Masa Corporal (IMC)',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                          ),
                                          InkWell(
                                            onTap: () => ImcInfoDialog.mostrar(context),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryTeal),
                                                SizedBox(width: 3),
                                                Text(
                                                  '¿Qué significa?',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${perfil.imc!.toStringAsFixed(1)} kg/m² — ${perfil.clasificacionImc}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: perfil.colorImc,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── TARJETA 2: RED DE EMERGENCIA SOS Y MÉDICA ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🆘', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              'Red de Emergencia y Médica',
                              style: AppTypography.subtitulo().copyWith(
                                color: AppColors.emergencyRed,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                        _buildItemVisual(
                          icono: Icons.person_pin_circle_outlined,
                          titulo: 'Familiar / Contacto SOS de Emergencia',
                          valor: perfil?.contactoEmergenciaNombre?.isNotEmpty == true
                              ? '${perfil!.contactoEmergenciaNombre!} (${perfil.contactoEmergenciaParentesco})'
                              : 'Sin registrar',
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.phone_in_talk_outlined,
                          titulo: 'Teléfono de Urgencias',
                          valor: perfil?.contactoEmergenciaTelefono?.isNotEmpty == true
                              ? perfil!.contactoEmergenciaTelefono!
                              : 'Sin registrar',
                          valorColor: AppColors.emergencyRed,
                          destacarValor: true,
                          accionDerecha: perfil?.contactoEmergenciaTelefono?.isNotEmpty == true
                              ? IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: AppColors.emergencyRed),
                                  icon: const Icon(Icons.call, color: Colors.white, size: 22),
                                  onPressed: () => CallService.realizarLlamada(perfil!.contactoEmergenciaTelefono!),
                                )
                              : null,
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.medical_services_outlined,
                          titulo: 'Médico Tratante / Especialista',
                          valor: perfil?.medicoTratante?.isNotEmpty == true
                              ? '${perfil!.medicoTratante!} ${perfil.telefonoMedico?.isNotEmpty == true ? "(Tel: ${perfil.telefonoMedico})" : ""}'
                              : 'No especificado',
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.local_hospital_outlined,
                          titulo: 'Clínica / Hospital de Urgencias Preferido',
                          valor: perfil?.clinicaPreferida ?? 'Hospital General',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── TARJETA 3: ANTECEDENTES Y HISTORIAL CLÍNICO ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🩺', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              'Historial Clínico y Diagnósticos',
                              style: AppTypography.subtitulo().copyWith(
                                color: AppColors.primaryTeal,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                        _buildItemVisual(
                          icono: Icons.medical_information_outlined,
                          titulo: 'Alergias Conocidas',
                          valor: (perfil?.alergias != null && perfil!.alergias.isNotEmpty)
                              ? perfil.alergias
                              : 'Ninguna registrada',
                          valorColor: perfil?.alergias != 'Ninguna' && perfil?.alergias.isNotEmpty == true 
                              ? AppColors.emergencyRed 
                              : null,
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.favorite_outline,
                          titulo: 'Enfermedades Conocidas / Diagnósticos',
                          valor: (perfil?.condiciones != null && perfil!.condiciones.isNotEmpty)
                              ? perfil.condiciones
                              : 'Ninguna registrada',
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.healing_outlined,
                          titulo: 'Cirugías Previas',
                          valor: (perfil?.cirugias != null && perfil!.cirugias.isNotEmpty)
                              ? perfil.cirugias
                              : 'Ninguna registrada',
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.hearing_outlined,
                          titulo: 'Dispositivos de Apoyo',
                          valor: (perfil?.dispositivosMedicos != null && perfil!.dispositivosMedicos.isNotEmpty)
                              ? perfil.dispositivosMedicos
                              : 'Ninguno',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── TARJETA: TRATAMIENTOS Y DIAGNÓSTICOS MÉDICOS ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('🩺', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Text(
                                  'Tratamientos Médicos',
                                  style: AppTypography.subtitulo().copyWith(
                                    color: AppColors.primaryTeal,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => context.push('/perfil/editar'),
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryTeal),
                              label: const Text('Gestionar', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                            ),
                          ],
                        ),
                        const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                        ref.watch(tratamientosNotifierProvider).when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(color: AppColors.primaryTeal),
                            ),
                          ),
                          error: (e, _) => Text('Error al cargar tratamientos: $e', style: const TextStyle(color: AppColors.emergencyRed)),
                          data: (tratamientos) {
                            if (tratamientos.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No tienes tratamientos registrados aún. Puedes agregarlos al editar tu ficha médica.',
                                        style: AppTypography.pequeno().copyWith(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: tratamientos.map((t) {
                                final esCronico = t.esCronico ?? false;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundSecondary,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(esCronico ? '🩺' : '📋', style: const TextStyle(fontSize: 20)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.diagnostico,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${esCronico ? "Tratamiento permanente" : t.textoProgreso} • ${t.medicoTratante ?? "Médico particular"}',
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: t.esCompletado ? Colors.grey.shade200 : AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          t.textoEstado,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: t.esCompletado ? AppColors.textSecondary : AppColors.primaryTeal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── TARJETA 4: NOTAS ADICIONALES ──
                if (perfil?.notasAdicionales?.isNotEmpty == true) ...[
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📝', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Text(
                                'Notas Especiales de Cuidado',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 22, thickness: 1.5, color: AppColors.border),
                          Text(
                            perfil!.notasAdicionales!,
                            style: AppTypography.cuerpo().copyWith(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── TARJETA: CERTIFICADO DE PRIVACIDAD Y HABEAS DATA ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppColors.healthGreen, size: 26),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Seguridad y Habeas Data',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF22C55E)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ley 1581 / 2012',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),
                        const Text(
                          'Tus datos sensibles de salud están encriptados y protegidos bajo el marco legal de Colombia. Se emplean exclusivamente para tus recordatorios de salud y atención de emergencias.',
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const HabeasDataDialog(),
                            );
                          },
                          icon: const Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryTeal),
                          label: const Text(
                            'Consultar Derechos ARCO y Términos',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryTeal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── BOTÓN CERRAR SESIÓN ──
                OutlinedButton.icon(
                  onPressed: _confirmarCerrarSesion,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.emergencyRed, size: 26),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    side: const BorderSide(color: AppColors.emergencyRed, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    backgroundColor: AppColors.cardBackground,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemVisual({
    required IconData icono,
    required String titulo,
    required String valor,
    Color? valorColor,
    bool destacarValor = false,
    Widget? accionDerecha,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.primaryTeal, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTypography.pequeno().copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: AppTypography.cuerpo().copyWith(
                    fontSize: 18,
                    fontWeight: destacarValor ? FontWeight.bold : FontWeight.w600,
                    color: valorColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (accionDerecha != null) ...[
            const SizedBox(width: 8),
            accionDerecha,
          ],
        ],
      ),
    );
  }
}
