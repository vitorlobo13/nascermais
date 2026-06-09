import 'package:flutter/material.dart';
import '../models/gestante.dart';
import '../services/ficha_service.dart';

class DetalhesDialogs {
  static final FichaService _fichaService = FichaService();

  static void mostrarDialogoNovoCartao(BuildContext context, Gestante gestante, VoidCallback onAtualizar) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Cartão'),
        content: TextField(
          controller: controller, 
          decoration: const InputDecoration(hintText: 'Título do cartão'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _fichaService.adicionarCartao(gestante, controller.text);
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

  static void mostrarDialogoEditarTitulo(BuildContext context, Gestante gestante, int index, VoidCallback onAtualizar) {
    final controller = TextEditingController(text: gestante.ficha[index].titulo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Título'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _fichaService.editarTituloCartao(gestante, index, controller.text);
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

  static void mostrarDialogoAdicionarItem(BuildContext context, Gestante gestante, CartaoFicha cartao, VoidCallback onAtualizar) {
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
                await _fichaService.adicionarSubtopico(gestante, cartao, itemController.text);
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

  static void mostrarImportarFicha(BuildContext context, Gestante gestante, List<Gestante> todasAsGestantes, VoidCallback onAtualizar) {
    final outras = _fichaService.obterOutrasGestantes(gestante, todasAsGestantes);
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
                    await _fichaService.importarFicha(gestante, g);
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
