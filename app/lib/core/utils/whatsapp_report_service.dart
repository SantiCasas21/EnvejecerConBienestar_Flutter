import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/historial/data/models/resumen_adherencia_model.dart';
import '../../features/historial/data/models/historial_toma_model.dart';

/// Servicio para construir y compartir reportes de adherencia vía WhatsApp o texto
class WhatsAppReportService {
  /// Construye el texto formateado con emojis para WhatsApp
  static String construirMensajeReporte({
    required String nombrePaciente,
    required ResumenAdherenciaModel resumen,
    String? periodoNombre,
  }) {
    final sb = StringBuffer();
    sb.writeln('🌿 *ENVEJECER CON BIENESTAR*');
    sb.writeln('📋 *Reporte de Salud y Cumplimiento*');
    sb.writeln('👤 *Paciente:* $nombrePaciente');
    if (periodoNombre != null && periodoNombre.isNotEmpty) {
      sb.writeln('🗓️ *Periodo:* $periodoNombre (${resumen.fechaInicio} al ${resumen.fechaFin})');
    } else {
      sb.writeln('🗓️ *Periodo:* ${resumen.fechaInicio} al ${resumen.fechaFin}');
    }
    sb.writeln('─────────────────────────────');

    // Sección Medicamentos
    sb.writeln('💊 *ADHERENCIA A MEDICAMENTOS:*');
    sb.writeln('• Cumplimiento Global: *${resumen.porcentajeAdherenciaGlobal.toStringAsFixed(1)}%*');
    sb.writeln('• Tomas Registradas: *${resumen.totalTomadas} de ${resumen.totalEsperadas} esperadas*');
    if (resumen.totalPospuestas > 0) {
      sb.writeln('• Tomas Pospuestas: ${resumen.totalPospuestas}');
    }
    if (resumen.totalOmitidas > 0) {
      sb.writeln('• Tomas Omitidas: ${resumen.totalOmitidas}');
    }

    if (resumen.medicamentosAdherencia.isNotEmpty) {
      sb.writeln('');
      sb.writeln('📋 *Detalle por Medicamento:*');
      for (final med in resumen.medicamentosAdherencia) {
        final stockWarn = (med.cantidadRestante != null && med.cantidadRestante! <= 5)
            ? ' ⚠️ _(Quedan ${med.cantidadRestante} pastillas)_'
            : '';
        sb.writeln('• ${med.icono} *${med.nombre}* (${med.miligramos ?? ""}): ${med.porcentaje.toStringAsFixed(0)}% (${med.tomadas}/${med.esperadas})$stockWarn');
      }
    }

    // Sección Racha
    if (resumen.racha != null && resumen.racha!.rachaActual > 0) {
      sb.writeln('');
      sb.writeln('🔥 *RACHA DE BIENESTAR:*');
      sb.writeln('• *${resumen.racha!.rachaActual} días consecutivos* cuidando su salud con constancia.');
    }

    // Sección Hábitos
    if (resumen.resumenHabitos.isNotEmpty) {
      sb.writeln('');
      sb.writeln('🌱 *HÁBITOS DE VIDA SALUDABLE:*');
      for (final hab in resumen.resumenHabitos) {
        sb.writeln('• ${hab.icono} *${hab.nombre}:* ${hab.cumplidos} de ${hab.totalDias} días (${hab.porcentaje.toStringAsFixed(0)}%)');
      }
    }

    sb.writeln('─────────────────────────────');
    sb.writeln('✨ _Generado con amor por Envejecer con Bienestar._');

    return sb.toString();
  }

  /// Comparte el reporte directamente en WhatsApp o abre selector nativo
  static Future<bool> compartirPorWhatsApp({
    required String nombrePaciente,
    required ResumenAdherenciaModel resumen,
    String? periodoNombre,
    String? telefonoDestino,
  }) async {
    final mensaje = construirMensajeReporte(
      nombrePaciente: nombrePaciente,
      resumen: resumen,
      periodoNombre: periodoNombre,
    );

    HapticFeedback.mediumImpact();

    try {
      final phoneParam = telefonoDestino != null && telefonoDestino.isNotEmpty
          ? 'phone=${telefonoDestino.replaceAll(RegExp(r'[^0-9]'), '')}&'
          : '';
      final url = Uri.parse('https://wa.me/?${phoneParam}text=${Uri.encodeComponent(mensaje)}');

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(mensaje, subject: 'Reporte de Salud - $nombrePaciente');
        return true;
      }
    } catch (_) {
      try {
        await Share.share(mensaje, subject: 'Reporte de Salud - $nombrePaciente');
        return true;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: mensaje));
        return false;
      }
    }
  }

  /// Construye el texto formateado con emojis para un solo día consultado
  static String construirMensajeReporteDiario({
    required String nombrePaciente,
    required String fechaTexto,
    required double adherencia,
    required List<HistorialTomaModel> tomas,
    required List<HabitoHistorialModel> habitos,
  }) {
    final sb = StringBuffer();
    sb.writeln('🌿 *ENVEJECER CON BIENESTAR*');
    sb.writeln('📋 *Reporte Diario de Salud*');
    sb.writeln('👤 *Paciente:* $nombrePaciente');
    sb.writeln('🗓️ *Fecha:* $fechaTexto');
    sb.writeln('─────────────────────────────');

    if (tomas.isEmpty) {
      sb.writeln('💊 *MEDICAMENTOS:* Sin prescripciones registradas este día.');
    } else {
      final tomadas = tomas.where((t) => t.fueTomada).length;
      sb.writeln('💊 *MEDICAMENTOS:* ${adherencia.round()}% de cumplimiento');
      sb.writeln('• Tomas realizadas: $tomadas de ${tomas.length}');
      for (final t in tomas) {
        final icono = t.fueTomada ? '✅' : (t.fuePospuesta ? '⏳' : '❌');
        final hora = t.horaProgramada;
        sb.writeln('  $icono *${t.medicamentoNombre}* ($hora) — ${t.estado.toUpperCase()}');
      }
    }

    if (habitos.isNotEmpty) {
      final cumplidos = habitos.where((h) => h.cumplido).length;
      sb.writeln('');
      sb.writeln('🌱 *HÁBITOS DE BIENESTAR:* ($cumplidos de ${habitos.length} cumplidos)');
      for (final h in habitos) {
        final icono = h.cumplido ? '⭐' : '🌱';
        sb.writeln('  $icono *${h.nombreFormateado}:* ${h.porcentaje.round()}%');
      }
    }

    sb.writeln('─────────────────────────────');
    sb.writeln('✨ _Generado con amor por Envejecer con Bienestar._');
    return sb.toString();
  }

  /// Comparte el reporte diario directamente en WhatsApp o abre selector nativo
  static Future<bool> compartirReporteDiarioPorWhatsApp({
    required String nombrePaciente,
    required String fechaTexto,
    required double adherencia,
    required List<HistorialTomaModel> tomas,
    required List<HabitoHistorialModel> habitos,
    String? telefonoDestino,
  }) async {
    final mensaje = construirMensajeReporteDiario(
      nombrePaciente: nombrePaciente,
      fechaTexto: fechaTexto,
      adherencia: adherencia,
      tomas: tomas,
      habitos: habitos,
    );

    HapticFeedback.mediumImpact();

    try {
      final phoneParam = telefonoDestino != null && telefonoDestino.isNotEmpty
          ? 'phone=${telefonoDestino.replaceAll(RegExp(r'[^0-9]'), '')}&'
          : '';
      final url = Uri.parse('https://wa.me/?${phoneParam}text=${Uri.encodeComponent(mensaje)}');

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(mensaje, subject: 'Reporte Diario - $nombrePaciente');
        return true;
      }
    } catch (_) {
      try {
        await Share.share(mensaje, subject: 'Reporte Diario - $nombrePaciente');
        return true;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: mensaje));
        return false;
      }
    }
  }
}
