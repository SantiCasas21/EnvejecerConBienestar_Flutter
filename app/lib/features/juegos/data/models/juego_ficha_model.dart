class JuegoFicha {
  final int id;
  final String valor;
  final bool estaVolteada;
  final bool estaEmparejada;

  const JuegoFicha({
    required this.id,
    required this.valor,
    this.estaVolteada = false,
    this.estaEmparejada = false,
  });

  JuegoFicha copyWith({bool? estaVolteada, bool? estaEmparejada}) {
    return JuegoFicha(
      id: id,
      valor: valor,
      estaVolteada: estaVolteada ?? this.estaVolteada,
      estaEmparejada: estaEmparejada ?? this.estaEmparejada,
    );
  }
}
