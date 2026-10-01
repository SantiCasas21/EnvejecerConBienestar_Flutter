import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/medicamentos/data/models/medicamento_model.dart';
import '../../features/medicamentos/presentation/widgets/alarma_toma_dialog.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// Bandera para pruebas unitarias automatizadas
  static bool isTestMode = false;

  /// Retorna true si las notificaciones deben ejecutarse en modo simulado (Web o Tests)
  static bool get _esSimulado => kIsWeb || isTestMode;

  /// Inicializa los timezones y el motor nativo de notificaciones locales.
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inicializar bases de datos de zonas horarias
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/Bogota'));
      } catch (_) {
        if (tz.timeZoneDatabase.locations.isNotEmpty) {
          tz.setLocalLocation(tz.timeZoneDatabase.locations.values.first);
        }
      }

      // 2. Configurar notificaciones nativas en plataformas móviles
      if (!_esSimulado) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        await _notificationsPlugin.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('[NotificationService] Notificación tocada con payload: ${response.payload}');
          },
        );
      }
      _isInitialized = true;
      debugPrint('[NotificationService] Inicializado correctamente.');
    } catch (e) {
      debugPrint('[NotificationService] Error inicializando notificaciones: $e');
    }
  }

  /// Programa las alarmas diarias recurrentes para todas las tomas de un medicamento.
  static Future<void> programarRecordatorioMedicamento(Medicamento medicamento) async {
    if (!_isInitialized) await init();

    if (_esSimulado) {
      debugPrint(
        '[NotificationService Simulado] Alarmas diarias registradas para "${medicamento.nombre}" (${medicamento.horarioDiario.length} tomas diarias)',
      );
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medicacion_diaria',
        'Recordatorios de Medicamentos',
        channelDescription: 'Canal de alarmas prioritarias para tomas de pastillas',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final horarios = medicamento.horarioDiario;
      for (int i = 0; i < horarios.length; i++) {
        final h = horarios[i];
        final idNum = ((medicamento.id.hashCode).abs() * 37 + i) % 100000;
        final horaStr = '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          h.hour,
          h.minute,
        );
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _notificationsPlugin.zonedSchedule(
          id: idNum,
          title: '🔔 Hora de tu medicina: ${medicamento.nombre}',
          body: 'Toma programada a las $horaStr (${medicamento.miligramos ?? ""} mg). ¡Tu salud es lo primero!',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: '${medicamento.id}',
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Error programando recordatorio: $e');
    }
  }

  /// Pospone una toma durante [minutos] (por defecto 10 minutos) programando una alarma única.
  static Future<void> posponerRecordatorio(Medicamento medicamento, {int minutos = 10}) async {
    if (!_isInitialized) await init();

    final idSnooze = ((medicamento.id.hashCode).abs() * 37 + 99) % 100000;
    final now = DateTime.now();
    final fechaSnooze = now.add(Duration(minutes: minutos));
    final horaSnoozeStr = '${fechaSnooze.hour.toString().padLeft(2, '0')}:${fechaSnooze.minute.toString().padLeft(2, '0')}';

    if (_esSimulado) {
      debugPrint(
        '[NotificationService Simulado] Alarma de "${medicamento.nombre}" pospuesta por $minutos min (sonará a las $horaSnoozeStr)',
      );
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medicacion_pospuesta',
        'Recordatorios Pospuestos',
        channelDescription: 'Alertas secundarias para tomas de medicamentos pospuestas',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final tzNow = tz.TZDateTime.now(tz.local);
      final scheduledDate = tzNow.add(Duration(minutes: minutos));

      await _notificationsPlugin.zonedSchedule(
        id: idSnooze,
        title: '⏰ Recordatorio pospuesto: ${medicamento.nombre}',
        body: 'Han pasado los $minutos minutos. Es momento de tomar tu dosis de ${medicamento.nombre} ($horaSnoozeStr).',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '${medicamento.id}',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error posponiendo recordatorio: $e');
    }
  }

  /// Cancela todas las alarmas previas y reprograma los medicamentos activos del paciente.
  static Future<void> reprogramarTodasLasAlarmas(List<Medicamento> medicamentos) async {
    if (!_isInitialized) await init();

    if (_esSimulado) {
      debugPrint(
        '[NotificationService Simulado] Reprogramación completada para ${medicamentos.length} medicamentos activos.',
      );
      return;
    }

    try {
      await _notificationsPlugin.cancelAll();
      for (final med in medicamentos) {
        await programarRecordatorioMedicamento(med);
      }
      debugPrint(
        '[NotificationService] Sincronizadas y reprogramadas las alarmas de ${medicamentos.length} medicamentos.',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error reprogramando alarmas: $e');
    }
  }

  /// Emite una notificación inmediata sonora de prueba para validar volumen y vibración.
  static Future<void> probarAlarmaSonora() async {
    if (!_isInitialized) await init();

    if (_esSimulado) {
      debugPrint('[NotificationService Simulado] Prueba de alarma sonora simulada con éxito.');
      return;
    }

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
      debugPrint('[NotificationService] Error en prueba de alarma: $e');
    }
  }

  /// Cancela las alarmas programadas de un medicamento específico.
  static Future<void> cancelarNotificacion(dynamic medicamentoId) async {
    if (!_isInitialized) await init();
    if (_esSimulado) return;

    try {
      for (int i = 0; i < 8; i++) {
        final idNum = ((medicamentoId.hashCode).abs() * 37 + i) % 100000;
        await _notificationsPlugin.cancel(id: idNum);
      }
      // Cancelar también posible snooze
      final idSnooze = ((medicamentoId.hashCode).abs() * 37 + 99) % 100000;
      await _notificationsPlugin.cancel(id: idSnooze);
    } catch (e) {
      debugPrint('[NotificationService] Error cancelando notificación: $e');
    }
  }

  /// Abre de forma inmediata el diálogo accesible de alarma activa para una medicina.
  static Future<void> mostrarAlarmaActiva(
    BuildContext context,
    Medicamento medicamento, {
    TimeOfDay? horaToma,
  }) {
    return AlarmaTomaDialog.mostrar(
      context: context,
      medicamento: medicamento,
      horaToma: horaToma,
    );
  }
}
