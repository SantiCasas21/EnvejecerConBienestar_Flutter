import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/call_service.dart';
import '../../data/models/contacto_model.dart';
import '../providers/contactos_provider.dart';

class ContactoDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ContactoDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ContactoDetailScreen> createState() => _ContactoDetailScreenState();
}

class _ContactoDetailScreenState extends ConsumerState<ContactoDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _guardando = false;
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _categoriaController = TextEditingController();
  bool _esFavorito = false;
  bool _esEmergencia = false;

  static const List<String> _categoriasRapidas = [
    'Familia/Amigos',
    'Médico',
    'Cuidador',
    'Vecino/Otro',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _ubicacionController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _guardar(int idNum) async {
    if (!_formKey.currentState!.validate() || _guardando) return;
    HapticFeedback.mediumImpact();
    setState(() => _guardando = true);

    final data = {
      'nombre': _nombreController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'categoria': _categoriaController.text.trim().isNotEmpty
          ? _categoriaController.text.trim()
          : 'Familia/Amigos',
      'es_favorito': _esFavorito,
      'es_emergencia': _esEmergencia,
    };

    try {
      await ref.read(contactosNotifierProvider.notifier).updateContacto(idNum, data);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil de contacto actualizado'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  Future<void> _toggleRapido(Contacto contacto, int idNum, {bool? favorito, bool? emergencia}) async {
    HapticFeedback.selectionClick();
    final nuevoFav = favorito ?? contacto.esFavorito;
    final nuevoSos = emergencia ?? contacto.esEmergencia;

    await ref.read(contactosNotifierProvider.notifier).updateContacto(idNum, {
      'nombre': contacto.nombre,
      'telefono': contacto.telefono,
      'ubicacion': contacto.ubicacion,
      'categoria': contacto.categoria,
      'es_favorito': nuevoFav,
      'es_emergencia': nuevoSos,
    });

    if (!mounted) return;
    String msg = '';
    if (favorito != null) {
      msg = nuevoFav ? '⭐ Agregado a Favoritos' : 'Quitado de Favoritos';
    } else if (emergencia != null) {
      msg = nuevoSos ? '🚨 Marcado como Contacto SOS' : 'Quitado de Emergencia SOS';
    }
    if (msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: nuevoSos ? AppColors.emergencyRed : AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    HapticFeedback.lightImpact();
    final limpio = telefono.replaceAll(RegExp(r'\D'), '');
    final numero = limpio.length == 10 ? '57$limpio' : limpio;
    final url = Uri.parse('https://wa.me/$numero');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copiarTelefono(String telefono) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: telefono));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Número copiado: $telefono'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminar(int idNum, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar contacto?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Deseas quitar a "$nombre" de tu agenda de la app?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
            child: const Text('Sí, Eliminar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(contactosNotifierProvider.notifier).deleteContacto(idNum);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactosAsync = ref.watch(contactosNotifierProvider);
    final idNum = int.tryParse(widget.id) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Perfil de Contacto',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _isEditing ? 'Cancelar edición' : 'Editar contacto',
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, size: 26),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          contactosAsync.whenOrNull(
                data: (list) {
                  final c = list.where((x) => x.id.toString() == widget.id).firstOrNull;
                  if (c == null) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Eliminar contacto',
                    icon: const Icon(Icons.delete_outline_rounded, size: 26),
                    onPressed: () => _eliminar(idNum, c.nombre),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: contactosAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (list) {
              final contacto = list.where((c) => c.id.toString() == widget.id).firstOrNull;
              if (contacto == null) {
                return const Center(
                  child: Text('Contacto no encontrado', style: TextStyle(fontSize: 18)),
                );
              }

              if (!_isEditing) {
                _nombreController.text = contacto.nombre;
                _telefonoController.text = contacto.telefono;
                _ubicacionController.text = contacto.ubicacion;
                _categoriaController.text = contacto.categoria;
                _esFavorito = contacto.esFavorito;
                _esEmergencia = contacto.esEmergencia;
              }

              final avatarColor = contacto.esEmergencia
                  ? AppColors.emergencyRed
                  : AppColors.generarColorPorNombre(contacto.nombre);
              final inicial = contacto.nombre.trim().isNotEmpty
                  ? contacto.nombre.trim()[0].toUpperCase()
                  : '👤';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Cabecera Hero estilo ficha de celular ──
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: contacto.esEmergencia
                              ? [const Color(0xFFFFE4E6), Colors.white]
                              : [AppColors.primaryLight.withValues(alpha: 0.7), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: contacto.esEmergencia
                              ? AppColors.emergencyRed.withValues(alpha: 0.4)
                              : AppColors.primaryTeal.withValues(alpha: 0.25),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: avatarColor.withValues(alpha: 0.35), width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: avatarColor,
                              child: Text(
                                inicial,
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            contacto.nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (contacto.categoria.trim().isNotEmpty)
                                _ProfileBadge(
                                  label: contacto.categoria,
                                  bg: AppColors.primaryLight,
                                  fg: AppColors.primaryDark,
                                ),
                              if (contacto.esEmergencia)
                                const _ProfileBadge(
                                  label: '🚨 Contacto SOS',
                                  bg: Color(0xFFFFE4E6),
                                  fg: Color(0xFF9F1239),
                                ),
                              if (contacto.esFavorito)
                                const _ProfileBadge(
                                  label: '⭐ Favorito',
                                  bg: Color(0xFFFEF3C7),
                                  fg: Color(0xFF92400E),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Fila de Acciones Rápidas (1 toque estilo celular) ──
                    if (!_isEditing) ...[
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _QuickActionCircle(
                            icon: Icons.phone_rounded,
                            label: 'Llamar',
                            color: AppColors.successGreen,
                            bg: const Color(0xFFDCFCE7),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              CallService.realizarLlamada(contacto.telefono);
                            },
                          ),
                          _QuickActionCircle(
                            icon: Icons.sms_rounded,
                            label: 'SMS',
                            color: AppColors.primaryTeal,
                            bg: AppColors.primaryLight,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              CallService.enviarMensaje(contacto.telefono);
                            },
                          ),
                          _QuickActionCircle(
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF15803D),
                            bg: const Color(0xFFDCFCE7),
                            onTap: () => _abrirWhatsApp(contacto.telefono),
                          ),
                          _QuickActionCircle(
                            icon: contacto.esFavorito ? Icons.star_rounded : Icons.star_border_rounded,
                            label: contacto.esFavorito ? 'Favorito' : 'Hacer Fav.',
                            color: const Color(0xFFB45309),
                            bg: contacto.esFavorito ? const Color(0xFFFEF3C7) : Colors.white,
                            highlighted: contacto.esFavorito,
                            onTap: () => _toggleRapido(
                              contacto,
                              idNum,
                              favorito: !contacto.esFavorito,
                            ),
                          ),
                          _QuickActionCircle(
                            icon: Icons.emergency_rounded,
                            label: contacto.esEmergencia ? 'Es SOS' : 'Poner SOS',
                            color: AppColors.emergencyRed,
                            bg: contacto.esEmergencia ? const Color(0xFFFFE4E6) : Colors.white,
                            highlighted: contacto.esEmergencia,
                            onTap: () => _toggleRapido(
                              contacto,
                              idNum,
                              emergencia: !contacto.esEmergencia,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],

                    // ── Cuerpo: Modo Vista o Modo Edición ──
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Editar Información',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nombreController,
                                style: const TextStyle(fontSize: 17),
                                decoration: InputDecoration(
                                  labelText: 'Nombre completo',
                                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primaryTeal),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _telefonoController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 17),
                                decoration: InputDecoration(
                                  labelText: 'Teléfono',
                                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primaryTeal),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el teléfono' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _ubicacionController,
                                style: const TextStyle(fontSize: 17),
                                decoration: InputDecoration(
                                  labelText: 'Ubicación / Dirección',
                                  prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primaryTeal),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Categoría / Vínculo',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categoriasRapidas.map((cat) {
                                  final sel = _categoriaController.text.trim() == cat;
                                  return ChoiceChip(
                                    label: Text(cat),
                                    selected: sel,
                                    selectedColor: AppColors.primaryLight,
                                    onSelected: (_) => setState(() => _categoriaController.text = cat),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              SwitchListTile(
                                title: const Text('⭐ Marcar como Favorito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                value: _esFavorito,
                                activeThumbColor: AppColors.warningAmber,
                                onChanged: (val) => setState(() => _esFavorito = val),
                              ),
                              SwitchListTile(
                                title: const Text('🚨 Contacto de Emergencia (SOS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.emergencyRed)),
                                value: _esEmergencia,
                                activeThumbColor: AppColors.emergencyRed,
                                onChanged: (val) => setState(() => _esEmergencia = val),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: _guardando ? null : () => _guardar(idNum),
                                  icon: _guardando
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.save_rounded),
                                  label: const Text('Guardar Cambios', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Tarjeta de Teléfono con botón copiar
                      _PhoneInfoCard(
                        icon: Icons.phone_android_rounded,
                        iconColor: AppColors.primaryTeal,
                        titulo: 'Teléfono móvil',
                        valor: contacto.telefono,
                        trailing: OutlinedButton.icon(
                          onPressed: () => _copiarTelefono(contacto.telefono),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copiar', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(color: AppColors.primaryTeal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PhoneInfoCard(
                        icon: Icons.group_rounded,
                        iconColor: AppColors.secondaryLavender,
                        titulo: 'Categoría / Vínculo',
                        valor: contacto.categoria.isNotEmpty ? contacto.categoria : 'Familia/Amigos',
                      ),
                      const SizedBox(height: 12),
                      _PhoneInfoCard(
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.warningAmber,
                        titulo: 'Ubicación / Dirección',
                        valor: contacto.ubicacion.isNotEmpty ? contacto.ubicacion : 'Sin dirección registrada',
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _ProfileBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _QuickActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final bool highlighted;
  final VoidCallback onTap;

  const _QuickActionCircle({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: highlighted ? color : color.withValues(alpha: 0.3),
                    width: highlighted ? 2 : 1.2,
                  ),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String valor;
  final Widget? trailing;

  const _PhoneInfoCard({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.valor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
