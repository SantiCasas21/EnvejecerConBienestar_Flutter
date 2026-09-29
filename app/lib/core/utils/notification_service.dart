import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/medicamentos/data/models/medicamento_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(settings: initializationSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
    }
  }

  static Future<void> programarRecordatorioMedicamento(Medicamento medicamento) async {
    if (kIsWeb) {
      debugPrint('Web: Notificación simulada para ${medicamento.nombre}');
      return;
    }

    if (!_isInitialized) await init();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medicacion_diaria',
        'Recordatorios de Medicamentos',
        channelDescription: 'Canal de notificaciones para horas de toma de pastillas',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final horarios = medicamento.horarioDiario;
      for (int i = 0; i < horarios.length; i++) {
        final h = horarios[i];
        final idNum = ((medicamento.id.hashCode).abs() * 37 + i) % 100000;
        final horaStr = '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

        await _notificationsPlugin.show(
          id: idNum,
          title: '💊 Hora de tu medicina: ${medicamento.nombre}',
          body: 'Toma programada a las $horaStr (${medicamento.miligramos ?? ""} mg). ¡Tu salud es lo primero!',
          notificationDetails: notificationDetails,
        );
      }
    } catch (e) {
      debugPrint('Error programando recordatorio: $e');
    }
  }

  static Future<void> probarAlarmaSonora() async {
    if (kIsWeb) {
      debugPrint('Web: Prueba de alarma completada');
      return;
    }

    if (!_isInitialized) await init();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medicacion_diaria',
        'Recordatorios de Medicamentos',
        channelDescription: 'Canal para alarmas y recordatorios médicos prioritarios',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        id: 99999,
        title: '🔔 Prueba de Alarma y Sonido',
        body: '¡Excelente! Los recordatorios de Envejecer con Bienestar sonarán con fuerza en tu teléfono.',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error en prueba de alarma: $e');
    }
  }

  static Future<void> cancelarNotificacion(dynamic medicamentoId) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      for (int i = 0; i < 6; i++) {
        final idNum = ((medicamentoId.hashCode).abs() * 37 + i) % 100000;
        await _notificationsPlugin.cancel(id: idNum);
      }
    } catch (e) {
      debugPrint('Error cancelando notificación: $e');
    }
  }
}
