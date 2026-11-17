import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../data/models/mensaje_ia_model.dart';

class MensajeBurbujaWidget extends StatelessWidget {
  final MensajeIaModel mensaje;
  final bool confirmando;
  final void Function(int mensajeId, bool aceptar)? onConfirmarAccion;

  const MensajeBurbujaWidget({
    super.key,
    required this.mensaje,
    this.confirmando = false,
    this.onConfirmarAccion,
  });

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            esUsuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!esUsuario) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: esUsuario
                        ? AppColors.primaryTeal
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(esUsuario ? 18 : 4),
                      bottomRight: Radius.circular(esUsuario ? 4 : 18),
                    ),
                    border: esUsuario
                        ? null
                        : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    mensaje.contenido,
                    style: AppTypography.cuerpo().copyWith(
                      color: esUsuario ? Colors.white : AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Tarjeta de Alerta Preventiva (Ámbar) o Emergencia (Carmesí)
          if (!esUsuario &&
              (mensaje.alertaPreventiva != null &&
                  mensaje.alertaPreventiva!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            _AlertaClinicaCard(
              mensaje: mensaje.alertaPreventiva!,
              esEmergencia: mensaje.esEmergencia,
            ),
          ] else if (!esUsuario && mensaje.esEmergencia) ...[
            const SizedBox(height: 8),
            const _AlertaClinicaCard(
              mensaje:
                  'Si presentas síntomas graves, pulsa el botón SOS o acude a urgencias de inmediato.',
              esEmergencia: true,
            ),
          ],

          // Tarjeta de Confirmación en 1 toque para cambios en expediente
          if (!esUsuario && mensaje.accionPendiente != null) ...[
            const SizedBox(height: 8),
            _AccionPendienteCard(
              accion: mensaje.accionPendiente!,
              confirmando: confirmando,
              onConfirmar: onConfirmarAccion == null
                  ? null
                  : (aceptar) => onConfirmarAccion!(mensaje.id, aceptar),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertaClinicaCard extends StatelessWidget {
  final String mensaje;
  final bool esEmergencia;

  const _AlertaClinicaCard({
    required this.mensaje,
    required this.esEmergencia,
  });

  @override
  Widget build(BuildContext context) {
    final colorBorde =
        esEmergencia ? AppColors.emergencyRed : const Color(0xFFD97706);
    final colorFondo =
        esEmergencia ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB);
    final titulo = esEmergencia
        ? 'Atención Prioritaria de Emergencia'
        : 'Aviso Preventivo de Seguridad';

    return Container(
      margin: const EdgeInsets.only(left: 44),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esEmergencia
                    ? Icons.emergency_rounded
                    : Icons.warning_amber_rounded,
                color: colorBorde,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorBorde,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            style: AppTypography.cuerpo().copyWith(
              fontSize: 17,
              height: 1.4,
            ),
          ),
          if (esEmergencia) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.go('/contactos'),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 24),
                label: Text(
                  'Ir a Contactos SOS',
                  style: AppTypography.subtitulo().copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccionPendienteCard extends StatelessWidget {
  final AccionPendienteModel accion;
  final bool confirmando;
  final void Function(bool aceptar)? onConfirmar;

  const _AccionPendienteCard({
    required this.accion,
    required this.confirmando,
    this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 44),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_rounded,
                color: AppColors.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirmar cambio en tu app',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            accion.resumen,
            style: AppTypography.cuerpo().copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),
          if (accion.estaPendiente)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          confirmando ? null : () => onConfirmar?.call(false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          confirmando ? null : () => onConfirmar?.call(true),
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  accion.estaConfirmada
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: accion.estaConfirmada
                      ? AppColors.healthGreen
                      : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    accion.estaConfirmada
                        ? 'Guardado correctamente en tu expediente'
                        : 'Cambio cancelado por ti',
                    style: AppTypography.pequeno().copyWith(
                      fontWeight: FontWeight.w700,
                      color: accion.estaConfirmada
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
