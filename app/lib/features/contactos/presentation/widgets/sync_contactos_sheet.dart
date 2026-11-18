import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/contacts_service.dart';
import '../providers/contactos_provider.dart';

class SyncContactosSheet extends ConsumerStatefulWidget {
  const SyncContactosSheet({super.key});

  @override
  ConsumerState<SyncContactosSheet> createState() => _SyncContactosSheetState();
}

class _SyncContactosSheetState extends ConsumerState<SyncContactosSheet> {
  bool _cargando = true;
  bool _guardando = false;
  bool _permisoDenegado = false;
  bool _permisoPermanente = false;
  bool _noDisponible = false;
  List<Contact> _contactosTelefono = [];
  final Set<int> _seleccionados = {};
  String _busqueda = '';
  String _categoriaImportar = 'Familia/Amigos';
  bool _marcarFavoritos = false;
  bool _marcarEmergencia = false;

  @override
  void initState() {
    super.initState();
    _cargarAgenda();
  }

  Future<void> _cargarAgenda() async {
    setState(() {
      _cargando = true;
      _permisoDenegado = false;
      _permisoPermanente = false;
      _noDisponible = false;
    });

    final res = await PhoneContactsService.obtenerContactosDelTelefono();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _contactosTelefono = res.contactos;
      _permisoDenegado = res.permisoDenegado;
      _permisoPermanente = res.permisoPermanente;
      _noDisponible = res.noDisponibleEnPlataforma;
    });
  }

  Future<void> _importarSeleccionados() async {
    if (_seleccionados.isEmpty || _guardando) return;
    HapticFeedback.mediumImpact();
    setState(() => _guardando = true);

    final payload = _seleccionados.map((idx) {
      final c = _contactosTelefono[idx];
      final nombre = (c.displayName ?? 'Contacto').trim();
      final telefono = c.phones.first.number.trim();
      final direccion = c.addresses.isNotEmpty
          ? (c.addresses.first.formatted ?? '').trim()
          : '';
      return {
        'nombre': nombre,
        'telefono': telefono,
        'ubicacion': direccion,
        'categoria': _categoriaImportar,
        'icono': _categoriaImportar == 'Médico' ? '🩺' : '👤',
        'es_favorito': _marcarFavoritos,
        'es_emergencia': _marcarEmergencia,
      };
    }).toList();

    try {
      final res = await ref
          .read(contactosNotifierProvider.notifier)
          .sincronizarDesdeTelefono(payload);
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron sincronizar: $e'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final filtrados = <MapEntry<int, Contact>>[];
    final q = _busqueda.trim().toLowerCase();
    for (int i = 0; i < _contactosTelefono.length; i++) {
      final c = _contactosTelefono[i];
      final nombre = (c.displayName ?? '').toLowerCase();
      final tel = c.phones.isNotEmpty ? c.phones.first.number.toLowerCase() : '';
      if (q.isEmpty || nombre.contains(q) || tel.contains(q)) {
        filtrados.add(MapEntry(i, c));
      }
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill superior
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: AppColors.primaryDark,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sincronizar del Celular',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Elige a quienes quieres traer a tu app',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 28),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryTeal),
                      SizedBox(height: 16),
                      Text(
                        'Leyendo contactos de tu teléfono...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else if (_noDisponible)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.smartphone_rounded, size: 56, color: AppColors.primaryTeal),
                      const SizedBox(height: 12),
                      const Text(
                        'Disponible en tu Celular Android',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'La sincronización directa con la agenda del teléfono funciona en la aplicación instalada (APK) en tu celular. Desde la web puedes agregar contactos manualmente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_permisoDenegado)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_person_rounded, size: 56, color: AppColors.warningAmber),
                      const SizedBox(height: 12),
                      const Text(
                        'Necesitamos permiso para ver tus contactos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Solo leeremos nombres y teléfonos para que no tengas que escribirlos a mano.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _permisoPermanente
                              ? PhoneContactsService.abrirAjustesPermisos
                              : _cargarAgenda,
                          icon: const Icon(Icons.settings_rounded),
                          label: Text(
                            _permisoPermanente ? 'Abrir Ajustes del Celular' : 'Conceder Permiso',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Buscador dentro de la agenda
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Buscar en tu teléfono...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),

                // Opciones rápidas al importar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      FilterChip(
                        selected: _marcarEmergencia,
                        label: const Text('🚨 Marcar SOS'),
                        selectedColor: const Color(0xFFFFE4E6),
                        checkmarkColor: AppColors.emergencyRed,
                        onSelected: (v) => setState(() => _marcarEmergencia = v),
                      ),
                      FilterChip(
                        selected: _marcarFavoritos,
                        label: const Text('⭐ Favorito'),
                        selectedColor: const Color(0xFFFEF3C7),
                        checkmarkColor: const Color(0xFF92400E),
                        onSelected: (v) => setState(() => _marcarFavoritos = v),
                      ),
                      ChoiceChip(
                        selected: _categoriaImportar == 'Médico',
                        label: const Text('🩺 Médico'),
                        selectedColor: AppColors.primaryLight,
                        onSelected: (v) => setState(
                          () => _categoriaImportar = v ? 'Médico' : 'Familia/Amigos',
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de contactos del teléfono
                Expanded(
                  child: filtrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron contactos con teléfono.',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: filtrados.length,
                          itemBuilder: (context, i) {
                            final entry = filtrados[i];
                            final idx = entry.key;
                            final c = entry.value;
                            final nombre = (c.displayName ?? 'Sin nombre').trim();
                            final tel = c.phones.first.number;
                            final checked = _seleccionados.contains(idx);
                            final avatarColor = AppColors.generarColorPorNombre(nombre);

                            return Card(
                              elevation: 0,
                              color: checked ? AppColors.primaryLight.withValues(alpha: 0.45) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: checked ? AppColors.primaryTeal : AppColors.border,
                                  width: checked ? 1.5 : 1,
                                ),
                              ),
                              child: CheckboxListTile(
                                value: checked,
                                activeColor: AppColors.primaryTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                secondary: CircleAvatar(
                                  backgroundColor: avatarColor,
                                  child: Text(
                                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '👤',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  tel,
                                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                                ),
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (val == true) {
                                      _seleccionados.add(idx);
                                    } else {
                                      _seleccionados.remove(idx);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),

                // Botón de importar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: (_seleccionados.isEmpty || _guardando)
                          ? null
                          : _importarSeleccionados,
                      icon: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.download_done_rounded, size: 24),
                      label: Text(
                        _seleccionados.isEmpty
                            ? 'Selecciona al menos 1 contacto'
                            : 'Importar ${_seleccionados.length} contacto${_seleccionados.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
