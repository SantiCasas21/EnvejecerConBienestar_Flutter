import 'package:flutter/material.dart';
import '../../../../core/utils/call_service.dart';
import '../../../auth/data/models/usuario_model.dart';
import '../../data/models/perfil_model.dart';

class CarneVitalCard extends StatelessWidget {
  final UsuarioModel usuario;
  final PerfilModel? perfil;
  final VoidCallback? onEditar;

  const CarneVitalCard({
    super.key,
    required this.usuario,
    required this.perfil,
    this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final docStr = (perfil?.numeroDocumento != null && perfil!.numeroDocumento!.isNotEmpty)
        ? '${perfil?.tipoDocumento ?? "CC"} ${perfil?.numeroDocumento}'
        : 'Sin documento';
    final epsStr = (perfil?.eps != null && perfil!.eps != 'No especificada')
        ? '${perfil!.eps} (${perfil?.regimenEps ?? "Contributivo"})'
        : 'EPS por configurar';
    final telSos = perfil?.contactoEmergenciaTelefono;
    final nombreSos = perfil?.contactoEmergenciaNombre ?? 'Contacto SOS';
    final alergiasRaw = perfil?.alergias.trim();
    final tieneAlergias = alergiasRaw != null && alergiasRaw.isNotEmpty && alergiasRaw.toLowerCase() != 'ninguna';
    final alergiasStr = tieneAlergias ? alergiasRaw : 'Ninguna registrada';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)], // Teal Calma y Vitalidad
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Encabezado Institucional Flexible (Sin desborde <= 360dp) ──
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 17),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'CARNÉ VITAL DE SALUD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    usuario.esCuidador ? '🛡️ Cuidador' : '👤 Paciente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Datos de Identidad y Chips Espaciosos (Tipo Pasaporte) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  usuario.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
              ),
              if (onEditar != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Editar Ficha Médica',
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                    onPressed: onEditar,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Chips/Badges independientes con Wrap para máxima respiración
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Badge Documento
              _buildBadge(
                icono: '🪪 ',
                texto: docStr,
              ),
              // Badge Edad
              _buildBadge(
                icono: '🎂 ',
                texto: perfil?.textoEdad ?? 'Edad no reg.',
              ),
              // Badge Código Vinculación
              if (usuario.codigoVinculacion != null && usuario.codigoVinculacion!.isNotEmpty)
                _buildBadge(
                  icono: '🏷️ ',
                  texto: usuario.codigoVinculacion!,
                ),
              // Badge EPS
              _buildBadge(
                icono: '🏥 ',
                texto: epsStr,
              ),
            ],
          ),

          // ── 3. Separador Elegante de Pasaporte ──
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 16),

          // ── 4. Badges de Triage Clínico en Cuadrícula Simétrica ──
          // Fila 1: Sangre e IMC (2 Columnas proporcionales)
          Row(
            children: [
              // Tipo de Sangre
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6), // Rosa suave institucional
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🩸 ', style: TextStyle(fontSize: 16)),
                      Flexible(
                        child: Text(
                          'Tipo: ${perfil?.tipoSangre ?? "O+"}',
                          style: const TextStyle(
                            color: Color(0xFF9F1239), // Carmesí profundo
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // IMC Corporal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Menta suave
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚖️ ', style: TextStyle(fontSize: 16)),
                      Flexible(
                        child: Text(
                          perfil?.imc != null
                              ? 'IMC ${perfil!.imc!.toStringAsFixed(1)}'
                              : 'IMC Pend.',
                          style: const TextStyle(
                            color: Color(0xFF166534), // Verde salud
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fila 2: Alergias (Ancho completo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Ámbar suave
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('⚠️ ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    'Alergias: $alergiasStr',
                    style: const TextStyle(
                      color: Color(0xFF92400E), // Ámbar oscuro
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 5. Métricas de Referencia Flexibles (Presión y Movilidad) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      perfil?.presionHabitual ?? '120/80 mmHg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk_rounded, size: 19, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      perfil?.nivelMovilidad ?? 'Independiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 6. Botón SOS de Marcación Directa Accesible (56dp) ──
          if (telSos != null && telSos.trim().isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48), // Rojo Carmesí SOS
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 26),
                label: Text(
                  'Llamar SOS: $nombreSos',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => CallService.realizarLlamada(telSos),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_call, size: 22),
                label: const Text(
                  'Configurar Contacto SOS de Emergencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onEditar,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({required String icono, required String texto}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icono, style: const TextStyle(fontSize: 14)),
          Flexible(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
