class EcbDateUtils {
  static String getSaludo() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
  
  static String formatFecha(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
