class JuegosRepository {
  final List<Map<String, dynamic>> _historial = [];

  Future<void> savePuntaje(int puntaje, String nivel) async {
    _historial.add({
      'puntaje': puntaje,
      'nivel': nivel,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<List<dynamic>> getHistorial() async {
    return _historial;
  }
}
