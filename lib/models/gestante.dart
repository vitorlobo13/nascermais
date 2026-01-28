import 'dart:convert';

class Pagamento {
  double valor;
  DateTime data;
  String descricao;
  Pagamento({required this.valor, required this.data, required this.descricao});
  Map<String, dynamic> toJson() => {'valor': valor, 'data': data.toIso8601String(), 'descricao': descricao};
  factory Pagamento.fromJson(Map<String, dynamic> json) => Pagamento(valor: json['valor'], data: DateTime.parse(json['data']), descricao: json['descricao']);
}

class Subtopico {
  String texto;
  bool concluido;
  Subtopico({required this.texto, this.concluido = false});
  Map<String, dynamic> toJson() => {'texto': texto, 'concluido': concluido};
  factory Subtopico.fromJson(Map<String, dynamic> json) => Subtopico(texto: json['texto'], concluido: json['concluido'] ?? false);
}

class CartaoFicha {
  String titulo;
  bool concluido;
  List<Subtopico> subtopicos;
  CartaoFicha({required this.titulo, this.concluido = false, List<Subtopico>? subtopicos}) : subtopicos = subtopicos ?? [];
  Map<String, dynamic> toJson() => {'titulo': titulo, 'concluido': concluido, 'subtopicos': subtopicos.map((s) => s.toJson()).toList()};
  factory CartaoFicha.fromJson(Map<String, dynamic> json) => CartaoFicha(
    titulo: json['titulo'], 
    concluido: json['concluido'] ?? false, 
    subtopicos: (json['subtopicos'] as List?)?.map((s) => Subtopico.fromJson(s)).toList() ?? []
  );
}

class Gestante {
  String nome;
  DateTime dppFinal;
  String maternidade;
  String classificacaoRisco;
  String? fotoPath; // NOVO
  List<CartaoFicha> ficha;
  double valorContrato;
  List<Pagamento> pagamentos;
  bool contratoEntregue;

  Gestante({
    required this.nome,
    required this.dppFinal,
    required this.maternidade,
    required this.classificacaoRisco,
    this.fotoPath, // NOVO
    this.valorContrato = 0.0,
    this.contratoEntregue = false,
    List<CartaoFicha>? ficha,
    List<Pagamento>? pagamentos,
  }) : ficha = ficha ?? [], pagamentos = pagamentos ?? [];

  String get semanasHoje {
    final hoje = DateTime.now();
    final diferenca = dppFinal.difference(hoje).inDays;
    if (diferenca < 0) return 'Pós-parto';
    final semanas = (280 - diferenca) ~/ 7;
    final dias = (280 - diferenca) % 7;
    return '$semanas semanas e $dias dias';
  }

  double get totalPago => pagamentos.fold(0, (soma, p) => soma + p.valor);
  double get saldoDevedor => valorContrato - totalPago;

  Map<String, dynamic> toJson() => {
    'nome': nome, 'dppFinal': dppFinal.toIso8601String(), 'maternidade': maternidade,
    'classificacaoRisco': classificacaoRisco, 'fotoPath': fotoPath, // NOVO
    'ficha': ficha.map((f) => f.toJson()).toList(),
    'valorContrato': valorContrato, 'pagamentos': pagamentos.map((p) => p.toJson()).toList(),
    'contratoEntregue': contratoEntregue,
  };

  factory Gestante.fromJson(Map<String, dynamic> json) => Gestante(
    nome: json['nome'], dppFinal: DateTime.parse(json['dppFinal']), maternidade: json['maternidade'],
    classificacaoRisco: json['classificacaoRisco'], fotoPath: json['fotoPath'], // NOVO
    ficha: (json['ficha'] as List?)?.map((f) => CartaoFicha.fromJson(f)).toList() ?? [],
    valorContrato: (json['valorContrato'] as num?)?.toDouble() ?? 0.0,
    pagamentos: (json['pagamentos'] as List?)?.map((p) => Pagamento.fromJson(p)).toList() ?? [],
    contratoEntregue: json['contratoEntregue'] ?? false,
  );
}
