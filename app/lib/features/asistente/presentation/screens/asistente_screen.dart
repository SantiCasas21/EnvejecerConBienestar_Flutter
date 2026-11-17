import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../providers/asistente_provider.dart';
import '../widgets/mensaje_burbuja_widget.dart';

class AsistenteScreen extends ConsumerStatefulWidget {
  final int? pacienteId;
  final String? pacienteNombre;

  const AsistenteScreen({
    super.key,
    this.pacienteId,
    this.pacienteNombre,
  });

  @override
  ConsumerState<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends ConsumerState<AsistenteScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, String>> _sugerenciasRapidas = [
    {
      'label': '💊 ¿Qué medicinas me faltan hoy?',
      'prompt': '¿Qué medicamentos tengo pendientes por tomar hoy y a qué hora?',
    },
    {
      'label': '⚠️ Verificar medicina nueva',
      'prompt':
          'El médico me habló de un medicamento nuevo, ¿qué debo tener en cuenta según mis alergias y tratamientos?',
    },
    {
      'label': '💧 Registrar hábito de hoy',
      'prompt': 'Ayúdame a registrar que acabo de tomar 2 vasos de agua.',
    },
    {
      'label': '🌿 Sugerir hábitos para mí',
      'prompt':
          'Según mi rutina y mis actividades actuales, ¿qué hábitos saludables me sugieres empezar o mejorar hoy?',
    },
    {
      'label': '🩺 Preparar cita médica',
      'prompt':
          'Prepara un resumen breve de mi adherencia, tratamientos y 3 preguntas útiles para mi próxima cita médica.',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviar([String? textoDirecto]) {
    final texto = (textoDirecto ?? _controller.text).trim();
    if (texto.isEmpty) return;
    if (textoDirecto == null) {
      _controller.clear();
    }
    ref
        .read(asistenteNotifierProvider(widget.pacienteId).notifier)
        .enviarMensaje(texto);
    _scrollAlFinal();
  }

  Future<void> _confirmarReinicio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Iniciar nueva charla?', style: AppTypography.subtitulo()),
        content: Text(
          'Se limpiará el historial de mensajes en pantalla. Tu expediente médico y medicamentos seguirán intactos.',
          style: AppTypography.cuerpo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Nueva charla', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      ref
          .read(asistenteNotifierProvider(widget.pacienteId).notifier)
          .reiniciarConversacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(asistenteNotifierProvider(widget.pacienteId));

    ref.listen(asistenteNotifierProvider(widget.pacienteId), (prev, next) {
      if ((prev?.mensajes.length ?? 0) != next.mensajes.length) {
        _scrollAlFinal();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistente de Salud IA',
              style: AppTypography.subtitulo().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.pacienteNombre != null)
              Text(
                'Paciente: ${widget.pacienteNombre}',
                style: AppTypography.pequeno().copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _confirmarReinicio,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner informativo de seguridad clínica
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primaryLight.withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Orientación preventiva basada en tu historial. No reemplaza la consulta médica.',
                      style: AppTypography.pequeno().copyWith(
                        fontSize: 14,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de mensajes o estado inicial amigable
            Expanded(
              child: state.cargandoHistorial
                  ? const Center(child: CircularProgressIndicator())
                  : state.mensajes.isEmpty
                      ? _VistaBienvenidaAsistente(
                          nombrePaciente: widget.pacienteNombre,
                          sugerencias: _sugerenciasRapidas,
                          onTapSugerencia: (p) => _enviar(p),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          itemCount: state.mensajes.length +
                              (state.enviando ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.mensajes.length) {
                              return const _IndicadorEscribiendo();
                            }
                            final msg = state.mensajes[index];
                            return MensajeBurbujaWidget(
                              mensaje: msg,
                              confirmando: state.confirmando,
                              onConfirmarAccion: (id, aceptar) {
                                ref
                                    .read(asistenteNotifierProvider(
                                            widget.pacienteId)
                                        .notifier)
                                    .confirmarAccion(id, aceptar);
                              },
                            );
                          },
                        ),
            ),

            if (state.error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.pendingBackground,
                child: Text(
                  state.error!,
                  style: AppTypography.pequeno().copyWith(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Chips de acceso rápido cuando ya hay conversación
            if (state.mensajes.isNotEmpty)
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _sugerenciasRapidas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = _sugerenciasRapidas[idx];
                    return ActionChip(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      label: Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      onPressed: state.enviando
                          ? null
                          : () => _enviar(item['prompt']!),
                    );
                  },
                ),
              ),

            // Barra de entrada accesible
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Escribe tu pregunta para el asistente de salud',
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        style: AppTypography.cuerpo(),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviar(),
                        decoration: InputDecoration(
                          hintText: 'Pregúntame sobre tus medicinas o salud...',
                          hintStyle: AppTypography.pequeno(),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: AppColors.primaryTeal,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Semantics(
                      button: true,
                      label: 'Enviar mensaje',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: state.enviando ? null : () => _enviar(),
                        child: const Icon(Icons.send_rounded, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VistaBienvenidaAsistente extends StatelessWidget {
  final String? nombrePaciente;
  final List<Map<String, String>> sugerencias;
  final void Function(String prompt) onTapSugerencia;

  const _VistaBienvenidaAsistente({
    required this.nombrePaciente,
    required this.sugerencias,
    required this.onTapSugerencia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.primaryTeal,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        nombrePaciente != null
                            ? 'Asistente para $nombrePaciente'
                            : '¡Hola! Soy Bienestar IA',
                        style: AppTypography.subtitulo().copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Conozco tu historial médico, alergias, tratamientos y hábitos para ayudarte con tranquilidad:\n'
                  '• Revisar si un medicamento nuevo cruza con tus alergias.\n'
                  '• Registrar o actualizar tus medicinas, citas y hábitos.\n'
                  '• Preparar resúmenes claros para tu cita médica.',
                  style: AppTypography.cuerpo().copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Puedes empezar tocando una opción:',
            style: AppTypography.subtitulo().copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...sugerencias.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => onTapSugerencia(item['prompt']!),
                  child: Text(
                    item['label']!,
                    style: AppTypography.cuerpo().copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadorEscribiendo extends StatelessWidget {
  const _IndicadorEscribiendo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Revisando tu expediente...',
                  style: AppTypography.pequeno().copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
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
