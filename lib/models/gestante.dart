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
  CartaoFicha copiar() {
  return CartaoFicha(
    titulo: titulo,
    concluido: false, // Começa desmarcado para a nova gestante
    subtopicos: subtopicos.map((s) => Subtopico(
      texto: s.texto,
      concluido: false, // Começa desmarcado
    )).toList(),
  );
  }
}

class Gestante {
  int? id; // Chave primária
  String nome;
  DateTime dppFinal;
  String maternidade;
  String classificacaoRisco;
  String? fotoPath;
  List<CartaoFicha> ficha;
  double valorContrato;
  List<Pagamento> pagamentos;
  bool contratoEntregue;
  bool arquivada;

  Gestante({
    this.id,
    required this.nome,
    required this.dppFinal,
    required this.maternidade,
    required this.classificacaoRisco,
    this.fotoPath,
    this.valorContrato = 0.0,
    this.contratoEntregue = false,
    List<CartaoFicha>? ficha,
    List<Pagamento>? pagamentos,
    this.arquivada = false,
  }) : ficha = ficha ?? [], pagamentos = pagamentos ?? [];

  // Getters para lógica de negócio
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

  // Tradutor para o Banco de Dados
  Map<String, dynamic> toMap() {
    
    return {
      'id': id,
      'nome': nome,
      'dppFinal': dppFinal.toIso8601String(),
      'maternidade': maternidade,
      'classificacaoRisco': classificacaoRisco,
      'fotoPath': fotoPath,
      'ficha': jsonEncode(ficha.map((f) => f.toJson()).toList()),
      'valorContrato': valorContrato,
      'pagamentos': jsonEncode(pagamentos.map((p) => p.toJson()).toList()),
      'contratoEntregue': contratoEntregue ? 1 : 0,
      'arquivada': arquivada ? 1 : 0,
    };
  }

  factory Gestante.fromMap(Map<String, dynamic> map) {
    return Gestante(
      id: map['id'],
      nome: map['nome'],
      dppFinal: DateTime.parse(map['dppFinal']),
      maternidade: map['maternidade'],
      classificacaoRisco: map['classificacaoRisco'],
      fotoPath: map['fotoPath'],
      ficha: (jsonDecode(map['ficha']) as List).map((f) => CartaoFicha.fromJson(f)).toList(),
      valorContrato: (map['valorContrato'] as num).toDouble(),
      pagamentos: (jsonDecode(map['pagamentos']) as List).map((p) => Pagamento.fromJson(p)).toList(),
      contratoEntregue: map['contratoEntregue'] == 1,
      arquivada: map['arquivada'] == 1,
    );
  }
}

