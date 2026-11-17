import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

class CallService {
  /// Número nacional de emergencias por defecto (Colombia).
  static const String numeroEmergenciaNacional = '123';

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

  /// Flujo SOS seguro:
  /// 1. Evita toques accidentales con confirmación rápida de 1 toque.
  /// 2. Llama primero al contacto de emergencia configurado.
  /// 3. Al regresar a la app tras el intento de llamada (≥5s), si el contacto
  ///    no respondió, activa respaldo automático al 123 (Colombia).
  static Future<void> iniciarSosConRespaldo(
    BuildContext context, {
    String? telefonoContacto,
    String? nombreContacto,
    String numeroPais = numeroEmergenciaNacional,
  }) async {
    final tieneContacto =
        telefonoContacto != null && telefonoContacto.trim().isNotEmpty;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.emergency_rounded,
                color: AppColors.emergencyRed, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Confirmar Llamada SOS',
                style: AppTypography.subtitulo().copyWith(
                  color: AppColors.emergencyRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          tieneContacto
              ? 'Se llamará primero a ${nombreContacto ?? 'tu contacto de emergencia'} ($telefonoContacto).\n\n'
                  'Si no responde, al volver a la app se activará el respaldo automático al $numeroPais.'
              : 'No tienes un contacto de emergencia configurado. Se llamará directamente a la línea nacional de emergencias ($numeroPais).',
          style: AppTypography.cuerpo().copyWith(height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Fue un toque accidental',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 24),
              label: Text(
                tieneContacto ? 'Llamar a mi contacto' : 'Llamar al $numeroPais',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (!tieneContacto) {
      await realizarLlamada(numeroPais);
      return;
    }

    final inicioLlamada = DateTime.now();
    await realizarLlamada(telefonoContacto);

    if (!context.mounted) return;
    _SosReturnObserver(
      context: context,
      inicioLlamada: inicioLlamada,
      numeroPais: numeroPais,
    ).registrar();
  }
}

class _SosReturnObserver with WidgetsBindingObserver {
  final BuildContext context;
  final DateTime inicioLlamada;
  final String numeroPais;
  bool _resuelto = false;

  _SosReturnObserver({
    required this.context,
    required this.inicioLlamada,
    required this.numeroPais,
  });

  void registrar() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_resuelto) {
      _resuelto = true;
      WidgetsBinding.instance.removeObserver(this);

      final segundos = DateTime.now().difference(inicioLlamada).inSeconds;
      if (!context.mounted) return;

      // Si regresó muy rápido (<5s), evitamos marcar 123 automáticamente por posible toque/cuelgue accidental
      if (segundos < 5) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('¿Todo está bien?', style: AppTypography.subtitulo()),
            content: Text(
              'La llamada duró muy poco. ¿Deseas comunicarte con la línea de emergencias $numeroPais?',
              style: AppTypography.cuerpo(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Todo está bien', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  CallService.realizarLlamada(numeroPais);
                },
                child: Text('Llamar al $numeroPais',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }

      // Si pasó tiempo de timbre/espera (≥5s), iniciamos cuenta regresiva automática al 123
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _AutoFallbackSosDialog(numeroPais: numeroPais),
      );
    }
  }
}

class _AutoFallbackSosDialog extends StatefulWidget {
  final String numeroPais;
  const _AutoFallbackSosDialog({required this.numeroPais});

  @override
  State<_AutoFallbackSosDialog> createState() => _AutoFallbackSosDialogState();
}

class _AutoFallbackSosDialogState extends State<_AutoFallbackSosDialog> {
  int _restante = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_restante <= 1) {
        t.cancel();
        Navigator.of(context).pop();
        CallService.realizarLlamada(widget.numeroPais);
      } else {
        setState(() => _restante--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Respaldo Automático ${widget.numeroPais}',
        style: AppTypography.subtitulo().copyWith(
          color: AppColors.emergencyRed,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Si tu contacto no respondió, llamaremos automáticamente al ${widget.numeroPais} en $_restante segundos...',
        style: AppTypography.cuerpo(),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Ya me respondieron / Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop();
              CallService.realizarLlamada(widget.numeroPais);
            },
            child: Text(
              'Llamar al ${widget.numeroPais} ahora',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
