import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/contacto_model.dart';
import '../providers/contactos_provider.dart';
import '../widgets/add_contacto_dialog.dart';
import '../widgets/contacto_card.dart';
import '../widgets/sync_contactos_sheet.dart';

class ContactosScreen extends ConsumerStatefulWidget {
  const ContactosScreen({super.key});

  @override
  ConsumerState<ContactosScreen> createState() => _ContactosScreenState();
}

class _ContactosScreenState extends ConsumerState<ContactosScreen> {
  final _searchController = TextEditingController();
  String _busqueda = '';
  String _filtro = 'todos'; // todos, emergencia, favoritos, familia, medicos

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirAdd() async {
    HapticFeedback.lightImpact();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddContactoDialog(),
    );

    if (result != null) {
      await ref.read(contactosNotifierProvider.notifier).addContacto(result);
    }
  }

  void _abrirSincronizacion() async {
    HapticFeedback.lightImpact();
    final res = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SyncContactosSheet(),
    );

    if (res != null && mounted) {
      final creados = res['creados'] ?? 0;
      final omitidos = res['omitidos'] ?? 0;
      final texto = omitidos > 0
          ? '✅ $creados contacto(s) importado(s) ($omitidos ya existían)'
          : '✅ $creados contacto(s) importado(s) desde tu celular';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Contacto> _filtrar(List<Contacto> lista) {
    final q = _busqueda.trim().toLowerCase();
    return lista.where((c) {
      if (_filtro == 'emergencia' && !c.esEmergencia) return false;
      if (_filtro == 'favoritos' && !c.esFavorito) return false;
      if (_filtro == 'familia') {
        final cat = c.categoria.toLowerCase();
        if (!cat.contains('familia') && !cat.contains('amigo') && !cat.contains('hijo') && !cat.contains('cuidador')) {
          return false;
        }
      }
      if (_filtro == 'medicos') {
        final cat = c.categoria.toLowerCase();
        if (!cat.contains('médic') && !cat.contains('medic') && !cat.contains('doctor') && !cat.contains('salud')) {
          return false;
        }
      }

      if (q.isEmpty) return true;
      return c.nombre.toLowerCase().contains(q) ||
          c.telefono.toLowerCase().contains(q) ||
          c.categoria.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final contactosAsync = ref.watch(contactosNotifierProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final chipsHeight = (50.0 * textScale).clamp(50.0, 68.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mis Contactos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sincronizar con mi celular',
            icon: const Icon(Icons.sync_rounded, size: 28),
            onPressed: _abrirSincronizacion,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            color: AppColors.primaryTeal,
            onRefresh: () async {
              ref.invalidate(contactosNotifierProvider);
            },
            child: contactosAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error al cargar contactos: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: AppColors.emergencyRed),
                  ),
                ),
              ),
              data: (contactos) {
                final emergenciasCount = contactos.where((c) => c.esEmergencia).length;
                final favoritosCount = contactos.where((c) => c.esFavorito).length;
                final filtrados = _filtrar(contactos);

                final emergencias = filtrados.where((c) => c.esEmergencia).toList();
                final favoritos = filtrados.where((c) => c.esFavorito && !c.esEmergencia).toList();
                final otros = filtrados.where((c) => !c.esFavorito && !c.esEmergencia).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    // Banner / Botón destacado para sincronizar agenda del celular
                    Material(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _abrirSincronizacion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primaryTeal.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.contact_phone_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sincronizar con mi Celular',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Trae tus contactos y elige emergencias o favoritos',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.primaryDark,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Barra de búsqueda accesible
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _busqueda = v),
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o número...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal, size: 26),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _busqueda = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chips de filtro rápido
                    SizedBox(
                      height: chipsHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterPill(
                            label: 'Todos (${contactos.length})',
                            selected: _filtro == 'todos',
                            onTap: () => setState(() => _filtro = 'todos'),
                          ),
                          _FilterPill(
                            label: '🚨 Emergencia ($emergenciasCount)',
                            selected: _filtro == 'emergencia',
                            activeBg: const Color(0xFFFFE4E6),
                            activeFg: const Color(0xFF9F1239),
                            onTap: () => setState(() => _filtro = 'emergencia'),
                          ),
                          _FilterPill(
                            label: '⭐ Favoritos ($favoritosCount)',
                            selected: _filtro == 'favoritos',
                            activeBg: const Color(0xFFFEF3C7),
                            activeFg: const Color(0xFF92400E),
                            onTap: () => setState(() => _filtro = 'favoritos'),
                          ),
                          _FilterPill(
                            label: '👨‍👩‍👧 Familia',
                            selected: _filtro == 'familia',
                            onTap: () => setState(() => _filtro = 'familia'),
                          ),
                          _FilterPill(
                            label: '🩺 Médicos',
                            selected: _filtro == 'medicos',
                            onTap: () => setState(() => _filtro = 'medicos'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (contactos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Text('👥', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            const Text(
                              'Tu agenda está vacía',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sincroniza los contactos de tu celular o agrega manualmente a tu familia y médico de confianza.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15.5, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _abrirSincronizacion,
                                icon: const Icon(Icons.sync_rounded),
                                label: const Text('Sincronizar del Celular', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    else if (filtrados.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 52, color: AppColors.textSecondary),
                            const SizedBox(height: 10),
                            const Text(
                              'No hay contactos con ese filtro',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _busqueda = '';
                                  _filtro = 'todos';
                                });
                              },
                              child: const Text('Ver todos los contactos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (emergencias.isNotEmpty) ...[
                        const _SectionHeader(
                          titulo: '🚨 Contactos de Emergencia (SOS)',
                          color: AppColors.emergencyRed,
                        ),
                        ...emergencias.map((c) => ContactoCard(contacto: c)),
                        const SizedBox(height: 12),
                      ],
                      if (favoritos.isNotEmpty) ...[
                        const _SectionHeader(
                          titulo: '⭐ Favoritos',
                          color: Color(0xFF92400E),
                        ),
                        ...favoritos.map((c) => ContactoCard(contacto: c)),
                        const SizedBox(height: 12),
                      ],
                      if (otros.isNotEmpty) ...[
                        const _SectionHeader(
                          titulo: '👤 Agenda General',
                          color: AppColors.primaryDark,
                        ),
                        ...otros.map((c) => ContactoCard(contacto: c)),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAdd,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 26),
        label: const Text(
          'Agregar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titulo;
  final Color color;

  const _SectionHeader({required this.titulo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeBg;
  final Color? activeFg;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeBg,
    this.activeFg,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? (activeBg ?? AppColors.primaryLight) : Colors.white;
    final fg = selected ? (activeFg ?? AppColors.primaryDark) : AppColors.textPrimary;
    final border = selected ? fg.withValues(alpha: 0.6) : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border, width: selected ? 1.5 : 1),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
