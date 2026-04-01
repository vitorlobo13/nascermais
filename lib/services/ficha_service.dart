import 'package:flutter/material.dart';
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

  // --- DIÁLOGOS (UI helpers movidos da View) ---

  void mostrarDialogoNovoCartao(BuildContext context, Gestante gestante, VoidCallback onAtualizar) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Cartão'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Título do cartão')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await adicionarCartao(gestante, controller.text);
                Navigator.pop(ctx);
                onAtualizar();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void mostrarDialogoEditarTitulo(BuildContext context, Gestante gestante, int index, VoidCallback onAtualizar) {
    final controller = TextEditingController(text: gestante.ficha[index].titulo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Título'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await editarTituloCartao(gestante, index, controller.text);
                Navigator.pop(ctx);
                onAtualizar();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void mostrarDialogoAdicionarItem(BuildContext context, Gestante gestante, CartaoFicha cartao, VoidCallback onAtualizar) {
    final itemController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Novo item em: ${cartao.titulo}'),
        content: TextField(
          controller: itemController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Digite o nome do item...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (itemController.text.isNotEmpty) {
                await adicionarSubtopico(gestante, cartao, itemController.text);
                Navigator.pop(ctx);
                onAtualizar();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void mostrarImportarFicha(BuildContext context, Gestante gestante, List<Gestante> todasAsGestantes, VoidCallback onAtualizar) {
    final outras = obterOutrasGestantes(gestante, todasAsGestantes);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Copiar cartões de:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: outras.length,
              itemBuilder: (ctx2, index) {
                final g = outras[index];
                return ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(g.nome),
                  onTap: () async {
                    await importarFicha(gestante, g);
                    Navigator.pop(ctx);
                    onAtualizar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cartões importados (DPP, Maternidade e Risco ignorados)')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
