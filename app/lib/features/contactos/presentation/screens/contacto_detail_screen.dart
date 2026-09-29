import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/call_service.dart';
import '../providers/contactos_provider.dart';

class ContactoDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ContactoDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ContactoDetailScreen> createState() => _ContactoDetailScreenState();
}

class _ContactoDetailScreenState extends ConsumerState<ContactoDetailScreen> {
  bool _isEditing = false;
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _categoriaController = TextEditingController();
  bool _esFavorito = false;
  bool _esEmergencia = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _ubicacionController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  void _guardar(int idNum) async {
    final data = {
      'nombre': _nombreController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'categoria': _categoriaController.text.trim(),
      'es_favorito': _esFavorito,
      'es_emergencia': _esEmergencia,
    };

    await ref.read(contactosNotifierProvider.notifier).updateContacto(idNum, data);
    setState(() => _isEditing = false);
  }

  void _eliminar(int idNum) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar contacto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
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
        title: const Text('Detalle de Contacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: AppColors.contactsBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 28),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 28, color: Colors.white),
            onPressed: () => _eliminar(idNum),
          ),
        ],
      ),
      body: contactosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (list) {
          final contacto = list.where((c) => c.id.toString() == widget.id).firstOrNull;

          if (contacto == null) {
            return const Center(child: Text('Contacto no encontrado'));
          }

          if (!_isEditing) {
            _nombreController.text = contacto.nombre;
            _telefonoController.text = contacto.telefono;
            _ubicacionController.text = contacto.ubicacion;
            _categoriaController.text = contacto.categoria;
            _esFavorito = contacto.esFavorito;
            _esEmergencia = contacto.esEmergencia;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: contacto.esEmergencia ? AppColors.emergencyRed : AppColors.contactsBlue,
                    child: Text(
                      contacto.nombre.isNotEmpty ? contacto.nombre[0].toUpperCase() : '👤',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    contacto.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 20),

                // Botones Masivos de Llamar / Mensaje
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => CallService.realizarLlamada(contacto.telefono),
                          icon: const Icon(Icons.phone, color: Colors.white),
                          label: const Text('Llamar Ahora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.healthGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => CallService.enviarMensaje(contacto.telefono),
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: const Text('Enviar SMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.contactsBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Datos del Contacto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.contactsBlue)),
                            if (_isEditing)
                              ElevatedButton(
                                onPressed: () => _guardar(idNum),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.healthGreen, foregroundColor: Colors.white),
                                child: const Text('Guardar'),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildField('Nombre', contacto.nombre, _nombreController, _isEditing),
                        const SizedBox(height: 16),
                        _buildField('Teléfono', contacto.telefono, _telefonoController, _isEditing, keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildField('Ubicación / Dirección', contacto.ubicacion.isEmpty ? 'Sin dirección' : contacto.ubicacion, _ubicacionController, _isEditing),
                        const SizedBox(height: 16),
                        if (_isEditing) ...[
                          SwitchListTile(
                            title: const Text('Marcar como Favorito'),
                            value: _esFavorito,
                            onChanged: (val) => setState(() => _esFavorito = val),
                          ),
                          SwitchListTile(
                            title: const Text('🚨 Contacto de Emergencia (SOS)', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold)),
                            value: _esEmergencia,
                            onChanged: (val) => setState(() => _esEmergencia = val),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, String valor, TextEditingController controller, bool isEditing, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        if (isEditing)
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )
        else
          Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
