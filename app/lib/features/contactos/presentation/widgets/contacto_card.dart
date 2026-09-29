import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/contacto_model.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../config/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactoCard extends StatelessWidget {
  final Contacto contacto;

  const ContactoCard({super.key, required this.contacto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: EcbCard(
        onTap: () => context.go('/contactos/${contacto.id}'),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              radius: 24,
              child: Text(contacto.nombre.substring(0, 1), style: AppTypography.subtitulo()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contacto.nombre, style: AppTypography.subtitulo()),
                  Text(contacto.telefono, style: AppTypography.pequeno()),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: AppColors.primaryOrange, size: 32),
              onPressed: () async {
                final url = Uri.parse('tel:${contacto.telefono}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
