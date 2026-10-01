import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../../core/utils/pdf_report_service.dart';
import '../../../auth/data/models/usuario_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/cuidador_provider.dart';
import '../../../home/presentation/providers/metas_provider.dart';
import '../../../medicamentos/presentation/providers/medicamentos_provider.dart';
import '../../../medicamentos/presentation/providers/tratamientos_provider.dart';
import '../providers/perfil_provider.dart';
import '../widgets/carne_vital_card.dart';
import '../widgets/habeas_data_dialog.dart';
import '../widgets/imc_info_dialog.dart';
import '../../../medicamentos/presentation/widgets/tratamiento_card.dart';
import '../../../medicamentos/presentation/widgets/add_tratamiento_dialog.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _generandoPdf = false;

  void _copiarCodigoVinculacion(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Código $codigo copiado al portapapeles.'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _compartirWhatsApp(String codigo, String nombre) async {
    final mensaje =
        '¡Hola! Este es mi código de vinculación en Envejecer con Bienestar: *$codigo* para que puedas acompañarme y supervisar mis medicamentos y salud. 🌸';
    final url =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(mensaje)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(mensaje);
      }
    } catch (_) {
      await Share.share(mensaje);
    }
  }

  void _exportarReportePdf() async {
    final authUser = ref.read(authNotifierProvider).user;
    if (authUser == null) return;

    final perfil = ref.read(perfilNotifierProvider).value;
    bool incluirDocumento = false;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryTeal, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Exportar Expediente',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Se generará un informe médico digital completo con tus tratamientos, medicamentos, métricas basales y contactos SOS para tu cita médica o consulta.',
                    style: TextStyle(fontSize: 16, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: incluirDocumento,
                      activeColor: AppColors.primaryTeal,
                      title: Text(
                        'Incluir mi documento de identidad (${perfil?.tipoDocumento ?? "CC"} ${perfil?.numeroDocumento ?? "Sin registrar"})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Opcional. Desmárcalo si prefieres omitir tu documento al compartir el reporte.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          incluirDocumento = val ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Generar PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(130, 48),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true) return;

    setState(() => _generandoPdf = true);

    try {
      final perfilAsync = await ref.read(perfilNotifierProvider.future);
      final medicamentos = ref.read(medicamentosNotifierProvider).value ?? [];
      final metas = ref.read(metasNotifierProvider).value ?? [];
      final tratamientos = ref.read(tratamientosNotifierProvider).value ?? [];

      await PdfReportService.generarYCompartirReporte(
        usuario: authUser,
        perfil: perfilAsync,
        tratamientos: tratamientos,
        medicamentos: medicamentos,
        metas: metas,
        incluirDocumento: incluirDocumento,
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

  void _abrirAddTratamiento() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddTratamientoDialog(),
    );

    if (result != null) {
      try {
        await ref.read(tratamientosNotifierProvider.notifier).addTratamiento(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Tratamiento para ${result['diagnostico']} registrado exitosamente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.healthGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al guardar tratamiento: $e', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.emergencyRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
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
    final authUser = authState.user;

    // Si el usuario es Cuidador, mostramos vista limpia y adaptada sin datos clínicos
    if (authUser != null && authUser.esCuidador) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Mi Perfil de Cuidador',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar Sesión',
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.emergencyRed, size: 28),
              onPressed: _confirmarCerrarSesion,
            ),
          ],
        ),
        body: _buildPerfilCuidador(context, authUser),
      );
    }

    final perfilAsync = ref.watch(perfilNotifierProvider);
    final userName = authUser?.nombre ?? 'Usuario';
    final userEmail = authUser?.email ?? '';

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
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ficha Médica: $porcentajeEntero% Completa',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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

                // ── CARNÉ VITAL DE SALUD Y TRIAGE ──
                CarneVitalCard(
                  usuario: authUser ?? UsuarioModel(id: 1, email: userEmail, nombre: userName, rol: 'adulto_mayor'),
                  perfil: perfil,
                  onEditar: () => context.push('/perfil/editar'),
                ),
                const SizedBox(height: 20),

                // ── TARJETA DESTACADA: CÓDIGO DE VINCULACIÓN FAMILIAR (Solo Adulto Mayor) ──
                if (authState.user?.esAdultoMayor ?? true) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.qr_code_2_rounded,
                                  color: AppColors.primaryDark, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mi Código de Vinculación',
                                    style: AppTypography.subtitulo().copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Compártelo con tus familiares o cuidadores para supervisión',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primaryTeal.withValues(alpha: 0.5)),
                          ),
                          child: Center(
                            child: Text(
                              authState.user?.codigoVinculacion ?? 'ECB-1001',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copiarCodigoVinculacion(
                                    authState.user?.codigoVinculacion ??
                                        'ECB-1001'),
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                label: const Text('Copiar Código',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primaryTeal, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _compartirWhatsApp(
                                    authState.user?.codigoVinculacion ??
                                        'ECB-1001',
                                    userName),
                                icon: const Text('📲',
                                    style: TextStyle(fontSize: 18)),
                                label: const Text('WhatsApp',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  minimumSize: const Size(0, 48),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Datos Vitales e Identidad',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                        _buildItemVisual(
                          icono: Icons.badge_outlined,
                          titulo: 'Documento de Identidad',
                          valor: (perfil?.numeroDocumento != null && perfil!.numeroDocumento!.isNotEmpty)
                              ? '${perfil.tipoDocumento ?? "CC"} ${perfil.numeroDocumento}'
                              : 'Sin registrar',
                        ),
                        const SizedBox(height: 14),

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
                                titulo: 'EPS / Régimen',
                                valor: (perfil?.eps != null && perfil!.eps != 'No especificada')
                                    ? '${perfil.eps} (${perfil.regimenEps ?? "Contributivo"})'
                                    : 'No especificada',
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

                        // Indicador Visual de IMC (Sin desbordamiento, tipografía accesible >= 16sp)
                        if (perfil?.imc != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: perfil!.colorImc.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: perfil.colorImc, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Nivel 1: Icono de Salud y Valor Destacado ──
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: perfil.colorImc,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.accessibility_new_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Índice de Masa Corporal (IMC)',
                                            style: AppTypography.pequeno().copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${perfil.imc!.toStringAsFixed(1)} kg/m² — ${perfil.clasificacionImc}',
                                            style: AppTypography.cuerpo().copyWith(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: perfil.colorImc,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, thickness: 1, color: AppColors.border),
                                const SizedBox(height: 6),

                                // ── Nivel 2: Botón de Consulta Educativa Accesible (>= 48dp) ──
                                InkWell(
                                  onTap: () => ImcInfoDialog.mostrar(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          size: 22,
                                          color: AppColors.primaryTeal,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '¿Qué significa este valor para tu salud?',
                                            style: AppTypography.pequeno().copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Presión Habitual y Nivel de Movilidad
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.monitor_heart_outlined,
                                titulo: 'Presión Habitual',
                                valor: perfil?.presionHabitual?.isNotEmpty == true
                                    ? perfil!.presionHabitual!
                                    : '120/80 mmHg',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildItemVisual(
                                icono: Icons.directions_walk_rounded,
                                titulo: 'Nivel Movilidad',
                                valor: perfil?.nivelMovilidad?.isNotEmpty == true
                                    ? perfil!.nivelMovilidad!
                                    : 'Independiente',
                              ),
                            ),
                          ],
                        ),
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
                            Expanded(
                              child: Text(
                                'Red de Emergencia y Médica',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.emergencyRed,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                            Expanded(
                              child: Text(
                                'Historial Clínico y Diagnósticos',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                          icono: Icons.family_restroom_outlined,
                          titulo: 'Antecedentes Familiares',
                          valor: (perfil?.antecedentesFamiliares != null && perfil!.antecedentesFamiliares!.isNotEmpty)
                              ? perfil.antecedentesFamiliares!
                              : 'Ninguno registrado',
                        ),
                        const SizedBox(height: 14),

                        _buildItemVisual(
                          icono: Icons.restaurant_outlined,
                          titulo: 'Restricciones Alimentarias / Dieta Especial',
                          valor: (perfil?.restriccionesAlimentarias != null && perfil!.restriccionesAlimentarias!.isNotEmpty)
                              ? perfil.restriccionesAlimentarias!
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
                          children: [
                            const Text('🩺', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tratamientos Médicos',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _abrirAddTratamiento,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nuevo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                        ref.watch(tratamientosNotifierProvider).when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: AppColors.primaryTeal),
                            ),
                          ),
                          error: (e, _) => Text('Error al cargar tratamientos: $e', style: const TextStyle(color: AppColors.emergencyRed)),
                          data: (tratamientos) {
                            if (tratamientos.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    const Text('📋', style: TextStyle(fontSize: 34)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Aún no has registrado tratamientos',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Toca en "+ Nuevo" para agregar tus diagnósticos o terapias clínicas.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.pequeno().copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: tratamientos.map((t) {
                                return TratamientoCard(
                                  tratamiento: t,
                                  onToggleEstado: () async {
                                    final nuevo = t.esCompletado ? 'activo' : 'completado';
                                    await ref.read(tratamientosNotifierProvider.notifier).cambiarEstado(t.id, nuevo);
                                  },
                                  onEdit: () async {
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => AddTratamientoDialog(tratamiento: t),
                                    );
                                    if (result != null) {
                                      try {
                                        await ref.read(tratamientosNotifierProvider.notifier).updateTratamiento(t.id, result);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('✅ Tratamiento para ${result['diagnostico']} actualizado', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              backgroundColor: AppColors.healthGreen,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('❌ Error al actualizar tratamiento: $e', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              backgroundColor: AppColors.emergencyRed,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('¿Eliminar tratamiento?'),
                                        content: Text('Se eliminará "${t.diagnostico}". Los medicamentos vinculados se conservarán.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(tratamientosNotifierProvider.notifier).deleteTratamiento(t.id);
                                    }
                                  },
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
                              Expanded(
                                child: Text(
                                  'Notas Especiales de Cuidado',
                                  style: AppTypography.subtitulo().copyWith(
                                    color: AppColors.primaryTeal,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

  Widget _buildPerfilCuidador(BuildContext context, UsuarioModel user) {
    final pacientesAsync = ref.watch(cuidadorNotifierProvider);
    final initial = user.nombre.trim().isNotEmpty
        ? user.nombre.trim()[0].toUpperCase()
        : '👤';
    final avatarBgColor = AppColors.generarColorPorNombre(user.nombre);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── TARJETA PRINCIPAL DEL CUIDADOR ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: avatarBgColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: AppColors.primaryDark, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '🛡️ Cuidador',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── ADULTOS MAYORES A TU CUIDADO ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '👥 Familiares a tu Cuidado',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Ver Panel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          pacientesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
            ),
            error: (err, _) => Card(
              color: AppColors.pendingBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error al consultar familiares: $err'),
              ),
            ),
            data: (pacientes) {
              if (pacientes.isEmpty) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        const Text(
                          'Aún no tienes familiares vinculados',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dirígete al Panel de Supervisión para vincular a tu primer paciente ingresando su código.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Ir al Panel de Supervisión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: pacientes.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.generarColorPorNombre(p.nombre),
                          child: Text(
                            p.nombre.isNotEmpty
                                ? p.nombre[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${p.parentesco} • Código: ${p.codigoVinculacion ?? "N/A"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.todasTomasCompletadas
                                ? AppColors.completedLight
                                : AppColors.pendingBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '💊 ${p.tomasCumplidas}/${p.totalMedicamentos}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: p.todasTomasCompletadas
                                  ? AppColors.primaryDark
                                  : AppColors.emergencyRed,
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
          const SizedBox(height: 24),

          // ── INFORMACIÓN DE ROL Y ALCANCE ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primaryDark, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tus Capacidades como Cuidador',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '• Monitoreo de tomas y dosis diarias en tiempo real.\n'
                  '• Alertas tempranas de botiquín cuando el inventario esté bajo.\n'
                  '• Envío rápido de recordatorios por WhatsApp y llamadas de emergencia.\n'
                  '• Consulta de ficha médica de urgencia en cualquier momento.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── SEGURIDAD Y HABEAS DATA ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined,
                        color: AppColors.primaryTeal),
                    title: const Text(
                      'Habeas Data y Tratamiento de Datos',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'Ley 1581 de 2012 de Protección de Datos',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () => HabeasDataDialog.mostrar(context),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.app_shortcut_rounded,
                        color: AppColors.primaryDark),
                    title: Text(
                      'Envejecer con Bienestar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Versión 1.0.0 • Diseñado para la salud y tranquilidad familiar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── BOTÓN CERRAR SESIÓN ──
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _confirmarCerrarSesion,
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.emergencyRed, size: 22),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: AppColors.emergencyRed,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
