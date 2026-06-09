import '../models/gestante.dart';
import 'database_helper.dart';

class FichaService {
  final DatabaseHelper _db = DatabaseHelper();

  // --- CARTÕES ---

  Future<void> adicionarCartao(Gestante gestante, String titulo) async {
    gestante.ficha.add(CartaoFicha(titulo: titulo));
    await _db.updateGestante(gestante);
  }

  Future<void> editarTituloCartao(Gestante gestante, int index, String novoTitulo) async {
    gestante.ficha[index].titulo = novoTitulo;
    await _db.updateGestante(gestante);
  }

  Future<void> excluirCartao(Gestante gestante, int index) async {
    gestante.ficha.removeAt(index);
    await _db.updateGestante(gestante);
  }

  Future<void> alternarConclusaoCartao(Gestante gestante, CartaoFicha cartao, bool valor) async {
    cartao.concluido = valor;
    if (valor) {
      for (var sub in cartao.subtopicos) {
        sub.concluido = true;
      }
    }
    await _db.updateGestante(gestante);
  }

  Future<void> importarFicha(Gestante destino, Gestante origem) async {
    final proibidos = ['Dpp', 'Maternidade', 'Risco'];
    for (var cartao in origem.ficha) {
      if (!proibidos.any((p) => cartao.titulo.contains(p))) {
        destino.ficha.add(cartao.copiar());
      }
    }
    await _db.updateGestante(destino);
  }

  // --- SUBTÓPICOS ---

  Future<void> adicionarSubtopico(Gestante gestante, CartaoFicha cartao, String texto) async {
    cartao.subtopicos.add(Subtopico(texto: texto, concluido: false));
    cartao.concluido = false;
    await _db.updateGestante(gestante);
  }

  Future<void> excluirSubtopico(Gestante gestante, CartaoFicha cartao, Subtopico sub) async {
    cartao.subtopicos.remove(sub);
    await _db.updateGestante(gestante);
  }

  Future<void> alternarConclusaoSubtopico(Gestante gestante, CartaoFicha cartao, Subtopico sub, bool valor) async {
    sub.concluido = valor;
    cartao.concluido = cartao.subtopicos.every((s) => s.concluido);
    await _db.updateGestante(gestante);
  }

  List<Gestante> obterOutrasGestantes(Gestante atual, List<Gestante> todas) {
    return todas.where((g) => g.nome != atual.nome).toList();
  }
}
