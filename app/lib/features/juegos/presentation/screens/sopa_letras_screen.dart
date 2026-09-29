import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/victoria_puntaje_dialog.dart';

class SopaLetrasScreen extends ConsumerStatefulWidget {
  const SopaLetrasScreen({super.key});

  @override
  ConsumerState<SopaLetrasScreen> createState() => _SopaLetrasScreenState();
}

class _SopaLetrasScreenState extends ConsumerState<SopaLetrasScreen> {
  // Palabras y sus coordenadas exactas en la cuadrícula [fila, col]
  final Map<String, List<List<int>>> _palabrasInfo = {
    'AGUA': [
      [0, 0], [0, 1], [0, 2], [0, 3]
    ],
    'SALUD': [
      [1, 1], [1, 2], [1, 3], [1, 4], [1, 5]
    ],
    'VIDA': [
      [2, 1], [2, 2], [2, 3], [2, 4]
    ],
    'PASO': [
      [4, 1], [4, 2], [4, 3], [4, 4]
    ],
    'AMOR': [
      [6, 0], [6, 1], [6, 2], [6, 3]
    ],
    'SOL': [
      [7, 1], [7, 2], [7, 3]
    ],
  };

  final Map<String, Color> _palabraColores = {
    'AGUA': const Color(0xFF0284C7),
    'SALUD': const Color(0xFF10B981),
    'VIDA': const Color(0xFF8B5CF6),
    'PASO': const Color(0xFFF97316),
    'AMOR': const Color(0xFFEC4899),
    'SOL': const Color(0xFFF59E0B),
  };

  final Set<String> _palabrasEncontradas = {};

  final List<List<String>> _grid = [
    ['A', 'G', 'U', 'A', 'X', 'Y', 'Z', 'W'],
    ['B', 'S', 'A', 'L', 'U', 'D', 'K', 'L'],
    ['C', 'V', 'I', 'D', 'A', 'M', 'N', 'O'],
    ['D', 'E', 'F', 'G', 'H', 'P', 'Q', 'R'],
    ['E', 'P', 'A', 'S', 'O', 'S', 'T', 'U'],
    ['F', 'G', 'H', 'I', 'J', 'A', 'M', 'O'],
    ['A', 'M', 'O', 'R', 'K', 'L', 'M', 'R'],
    ['P', 'S', 'O', 'L', 'R', 'T', 'U', 'V'],
  ];

  Color? _colorDeCelda(int r, int c) {
    for (final entry in _palabrasInfo.entries) {
      if (_palabrasEncontradas.contains(entry.key)) {
        for (final pos in entry.value) {
          if (pos[0] == r && pos[1] == c) {
            return _palabraColores[entry.key];
          }
        }
      }
    }
    return null;
  }

  void _descubrirPalabra(String palabra) async {
    if (!_palabrasEncontradas.contains(palabra)) {
      setState(() {
        _palabrasEncontradas.add(palabra);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨ ¡Encontraste: ', style: TextStyle(fontSize: 16)),
              Text(palabra, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('! 🎉'),
            ],
          ),
          backgroundColor: _palabraColores[palabra] ?? AppColors.healthGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1400),
        ),
      );

      if (_palabrasEncontradas.length == _palabrasInfo.length) {
        const puntaje = 180;
        await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
              tipoJuego: 'Sopa de Letras',
              puntaje: puntaje,
            );

        if (mounted) {
          VictoriaPuntajeDialog.mostrar(
            context: context,
            nombreJuego: 'Sopa de Letras de Salud',
            puntaje: puntaje,
            mensajePersonalizado:
                '¡Hallaste todas las palabras saludables! El rastreo visual y la atención selectiva fortalecen la concentración cotidiana.',
            onJugarDeNuevo: () {
              setState(() => _palabrasEncontradas.clear());
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '🔤 Sopa de Letras',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.healthGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar sopa de letras',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: () => setState(() => _palabrasEncontradas.clear()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Contador y Progreso ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Palabras de Bienestar:',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.healthGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_palabrasEncontradas.length} / ${_palabrasInfo.length} halladas',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.healthGreen, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Fichas de Palabras a Buscar ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palabrasInfo.keys.map((p) {
                  final encontrada = _palabrasEncontradas.contains(p);
                  final color = _palabraColores[p] ?? AppColors.primaryTeal;

                  return FilterChip(
                    label: Text(
                      p,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: encontrada ? Colors.white : AppColors.textPrimary,
                        decoration: encontrada ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    selected: encontrada,
                    selectedColor: color,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
                    onSelected: (_) => _descubrirPalabra(p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Cuadrícula de Letras Iluminadas ──
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.healthGreen, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 64,
                      itemBuilder: (context, index) {
                        final row = index ~/ 8;
                        final col = index % 8;
                        final letra = _grid[row][col];
                        final highlightColor = _colorDeCelda(row, col);

                        return Container(
                          decoration: BoxDecoration(
                            color: highlightColor ?? const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: highlightColor ?? Colors.grey.shade200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              letra,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: highlightColor != null ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Consejo Senior ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.completedLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.healthGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('🌿', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toca las palabras que identifiques en la sopa de letras para resaltarlas y sumar puntos a tu récord.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
