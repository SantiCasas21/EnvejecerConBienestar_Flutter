import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/call_service.dart';
import '../../data/models/contacto_model.dart';

class ContactoCard extends StatelessWidget {
  final Contacto contacto;

  const ContactoCard({super.key, required this.contacto});

  @override
  Widget build(BuildContext context) {
    final esSos = contacto.esEmergencia;
    final esFav = contacto.esFavorito;

    final Color bgColor;
    final Color borderColor;
    if (esSos) {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = AppColors.emergencyRed.withValues(alpha: 0.65);
    } else if (esFav) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = AppColors.warningAmber.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.white;
      borderColor = AppColors.border;
    }

    final avatarColor = esSos
        ? AppColors.emergencyRed
        : AppColors.generarColorPorNombre(contacto.nombre);

    final inicial = contacto.nombre.trim().isNotEmpty
        ? contacto.nombre.trim()[0].toUpperCase()
        : '👤';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: esSos ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/contactos/${contacto.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: avatarColor,
                      child: Text(
                        inicial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (esSos || esFav)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Icon(
                            esSos ? Icons.emergency_rounded : Icons.star_rounded,
                            size: 15,
                            color: esSos ? AppColors.emergencyRed : AppColors.warningAmber,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contacto.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: esSos ? const Color(0xFF9F1239) : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contacto.telefono,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (esSos)
                            _BadgeChip(
                              texto: '🚨 Emergencia SOS',
                              bg: const Color(0xFFFFE4E6),
                              fg: const Color(0xFF9F1239),
                            ),
                          if (esFav)
                            _BadgeChip(
                              texto: '⭐ Favorito',
                              bg: const Color(0xFFFEF3C7),
                              fg: const Color(0xFF92400E),
                            ),
                          if (contacto.categoria.trim().isNotEmpty)
                            _BadgeChip(
                              texto: contacto.categoria,
                              bg: AppColors.primaryLight.withValues(alpha: 0.65),
                              fg: AppColors.primaryDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Llamar a ${contacto.nombre}',
                  button: true,
                  child: Material(
                    color: esSos ? AppColors.emergencyRed : AppColors.successGreen,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        CallService.realizarLlamada(contacto.telefono);
                      },
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String texto;
  final Color bg;
  final Color fg;

  const _BadgeChip({
    required this.texto,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
