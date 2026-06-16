import '../models/gestante.dart';

class FichaService {
  // --- CARTÕES ---

  Future<void> adicionarCartao(Gestante gestante, String titulo) async {
    gestante.ficha.add(CartaoFicha(titulo: titulo));
  }

  Future<void> editarTituloCartao(Gestante gestante, int index, String novoTitulo) async {
    gestante.ficha[index].titulo = novoTitulo;
  }

  Future<void> excluirCartao(Gestante gestante, int index) async {
    gestante.ficha.removeAt(index);
  }

  Future<void> alternarConclusaoCartao(Gestante gestante, CartaoFicha cartao, bool valor) async {
    cartao.concluido = valor;
    if (valor) {
      for (var sub in cartao.subtopicos) {
        sub.concluido = true;
      }
    }
  }

  Future<void> importarFicha(Gestante destino, Gestante origem) async {
    final proibidos = ['Dpp', 'Maternidade', 'Risco'];
    for (var cartao in origem.ficha) {
      if (!proibidos.any((p) => cartao.titulo.contains(p))) {
        destino.ficha.add(cartao.copiar());
      }
    }
  }

  // --- SUBTÓPICOS ---

  Future<void> adicionarSubtopico(Gestante gestante, CartaoFicha cartao, String texto) async {
    cartao.subtopicos.add(Subtopico(texto: texto, concluido: false));
    cartao.concluido = false;
  }

  Future<void> excluirSubtopico(Gestante gestante, CartaoFicha cartao, Subtopico sub) async {
    cartao.subtopicos.remove(sub);
  }

  Future<void> alternarConclusaoSubtopico(Gestante gestante, CartaoFicha cartao, Subtopico sub, bool valor) async {
    sub.concluido = valor;
    cartao.concluido = cartao.subtopicos.every((s) => s.concluido);
  }

  List<Gestante> obterOutrasGestantes(Gestante atual, List<Gestante> todas) {
    return todas.where((g) => g.nome != atual.nome).toList();
  }
}
