import 'package:flutter/material.dart';
import '../../../../core/widgets/ecb_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcbButton(
      text: '🚨 LLAMADA DE EMERGENCIA (SOS)',
      variant: EcbButtonVariant.emergency,
      onPressed: () async {
        final url = Uri.parse('tel:123'); // Emergency number
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
    );
  }
}
