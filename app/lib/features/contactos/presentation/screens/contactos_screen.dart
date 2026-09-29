import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/call_service.dart';
import '../providers/contactos_provider.dart';
import '../widgets/add_contacto_dialog.dart';

class ContactosScreen extends ConsumerWidget {
  const ContactosScreen({super.key});

  void _abrirAdd(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddContactoDialog(),
    );

    if (result != null) {
      ref.read(contactosNotifierProvider.notifier).addContacto(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactosAsync = ref.watch(contactosNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda de Contactos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: AppColors.contactsBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contactosNotifierProvider);
        },
        child: contactosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (contactos) {
            if (contactos.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  const Center(
                    child: Column(
                      children: [
                        Text('👥', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 12),
                        Text('No tienes contactos registrados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Agrega a tu familia o médico de confianza', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }

            final emergencias = contactos.where((c) => c.esEmergencia).toList();
            final favoritos = contactos.where((c) => c.esFavorito && !c.esEmergencia).toList();
            final otros = contactos.where((c) => !c.esFavorito && !c.esEmergencia).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (emergencias.isNotEmpty) ...[
                  const Text('🚨 CONTACTOS DE EMERGENCIA (SOS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.emergencyRed)),
                  const SizedBox(height: 8),
                  ...emergencias.map((c) => Card(
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.emergencyRed, width: 1.5)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.emergencyRed,
                            child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '🚨', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.emergencyRed)),
                          subtitle: Text(c.telefono, style: const TextStyle(fontSize: 16)),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: AppColors.emergencyRed, size: 32),
                            onPressed: () => CallService.realizarLlamada(c.telefono),
                          ),
                          onTap: () => context.push('/contactos/${c.id}'),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
                if (favoritos.isNotEmpty) ...[
                  const Text('⭐ Favoritos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  ...favoritos.map((c) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '⭐', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Text(c.telefono),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: AppColors.healthGreen, size: 28),
                            onPressed: () => CallService.realizarLlamada(c.telefono),
                          ),
                          onTap: () => context.push('/contactos/${c.id}'),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
                if (otros.isNotEmpty) ...[
                  const Text('👤 Otros Contactos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  ...otros.map((c) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '👤', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Text(c.telefono),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: AppColors.contactsBlue, size: 28),
                            onPressed: () => CallService.realizarLlamada(c.telefono),
                          ),
                          onTap: () => context.push('/contactos/${c.id}'),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirAdd(context, ref),
        backgroundColor: AppColors.contactsBlue,
        icon: const Icon(Icons.person_add, color: Colors.white, size: 28),
        label: const Text('Agregar Contacto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
