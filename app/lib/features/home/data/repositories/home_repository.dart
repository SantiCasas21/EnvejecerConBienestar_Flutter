import '../models/habito_model.dart';

class HomeRepository {
  final List<Habito> _habitos = [
    Habito(id: '1', usuarioId: '1', tipo: 'Agua', meta: 8, progresoActual: 0, fecha: DateTime.now()),
    Habito(id: '2', usuarioId: '1', tipo: 'Caminata', meta: 30, progresoActual: 0, fecha: DateTime.now()),
    Habito(id: '3', usuarioId: '1', tipo: 'Ejercicio', meta: 1, progresoActual: 0, fecha: DateTime.now()),
  ];

  Future<List<Habito>> getHabitos(DateTime fecha) async {
    return _habitos;
  }

  Future<Habito> crearHabito(Map<String, dynamic> data) async {
    final nuevoHabito = Habito.fromJson(data);
    _habitos.add(nuevoHabito);
    return nuevoHabito;
  }

  Future<void> actualizarProgreso(String id, int valor) async {
    final index = _habitos.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habitos[index] = _habitos[index].copyWith(progresoActual: valor);
    }
  }
}
