import 'package:url_launcher/url_launcher.dart';

class CallService {
  static Future<bool> realizarLlamada(String numero) async {
    final Uri url = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(url)) {
      return await launchUrl(url);
    }
    return false;
  }

  static Future<bool> enviarMensaje(String numero) async {
    final Uri url = Uri(scheme: 'sms', path: numero);
    if (await canLaunchUrl(url)) {
      return await launchUrl(url);
    }
    return false;
  }
}
