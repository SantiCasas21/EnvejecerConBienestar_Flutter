import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/contacts_service.dart';

class AddContactoDialog extends StatefulWidget {
  const AddContactoDialog({super.key});

  @override
  State<AddContactoDialog> createState() => _AddContactoDialogState();
}

class _AddContactoDialogState extends State<AddContactoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _categoriaController = TextEditingController(text: 'Familia/Amigos');
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

  void _importarNativo() async {
    final contact = await PhoneContactsService.seleccionarContacto();
    if (contact != null) {
      setState(() {
        _nombreController.text = contact.displayName ?? '';
        if (contact.phones.isNotEmpty) {
          _telefonoController.text = contact.phones.first.number;
        }
      });
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'nombre': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'categoria': _categoriaController.text.trim(),
        'es_favorito': _esFavorito,
        'es_emergencia': _esEmergencia,
        'icono': '👤',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '👤 Agregar Contacto',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.contactsBlue),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _importarNativo,
                icon: const Icon(Icons.contacts, color: AppColors.contactsBlue),
                label: const Text('Importar de la Agenda del Teléfono', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Teléfono (10 dígitos)',
                  hintText: 'Ej: 3001234567 o 6013456789',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el teléfono';
                  final digitos = v.replaceAll(RegExp(r'\D'), '');
                  if (digitos.length < 10) return 'Debe tener mínimo 10 dígitos (ej: 3001234567)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ubicacionController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Ubicación / Dirección',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Marcar como Favorito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                value: _esFavorito,
                onChanged: (val) => setState(() => _esFavorito = val ?? false),
                activeColor: AppColors.primaryOrange,
              ),
              CheckboxListTile(
                title: const Text('🚨 Contacto de EMERGENCIA (SOS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.emergencyRed)),
                value: _esEmergencia,
                onChanged: (val) => setState(() => _esEmergencia = val ?? false),
                activeColor: AppColors.emergencyRed,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.contactsBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Guardar Contacto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
