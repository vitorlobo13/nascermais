import 'package:flutter/material.dart';
import '../models/gestante.dart';
import '../services/image_convert_database.dart';
import 'editar_gestante_screen.dart';
import '../services/database_helper.dart';




class DetalhesGestanteScreen extends StatefulWidget {
  final Gestante gestante;
  final List<Gestante> todasAsGestantes;

  const DetalhesGestanteScreen({super.key, required this.gestante, required this.todasAsGestantes});

  @override
  State<DetalhesGestanteScreen> createState() => _DetalhesGestanteScreenState();
}

class _DetalhesGestanteScreenState extends State<DetalhesGestanteScreen> {
  final _imageProviderService = ImageProviderService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gestante.nome),
        backgroundColor: Colors.pink.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Importar cartões de outra gestante',
            onPressed: () => _importarFicha(widget.todasAsGestantes),
          ),
          IconButton(
            icon: Icon(widget.gestante.arquivada ? Icons.unarchive : Icons.archive),
            tooltip: widget.gestante.arquivada ? 'Desarquivar' : 'Arquivar',
            onPressed: () async {
              // 1. Inverte o status de arquivamento
              setState(() {
                widget.gestante.arquivada = !widget.gestante.arquivada;
              });
              // 2. Salva no Banco de Dados (O nosso UPDATE)
              await DatabaseHelper().updateGestante(widget.gestante);
              // 3. Mostra um aviso rápido e volta para a tela anterior
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.gestante.arquivada ? 'Gestante arquivada!' : 'Gestante reativada!')),
              );
              Navigator.pop(context, widget.gestante); // Volta para a Home com os dados atualizados
           },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final gestanteAtualizada = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarGestanteScreen(gestante: widget.gestante),
                ),
              );
              if (gestanteAtualizada != null) {
                setState(() {
                  // Atualiza a gestante localmente com os dados editados
                  // Como o objeto Gestante é passado por referência e modificado,
                  // e o onSave da HomeScreen lida com a lista completa,
                  // basta atualizar o objeto e o setState irá reconstruir a tela.
                  // A HomeScreen irá persistir a lista atualizada ao retornar.
                  widget.gestante.nome = gestanteAtualizada.nome;
                  widget.gestante.dppFinal = gestanteAtualizada.dppFinal;
                  widget.gestante.maternidade = gestanteAtualizada.maternidade;
                  widget.gestante.classificacaoRisco = gestanteAtualizada.classificacaoRisco;
                  widget.gestante.fotoPath = gestanteAtualizada.fotoPath;
                  widget.gestante.ficha = gestanteAtualizada.ficha;
                  // Outros campos como ficha, valorContrato, pagamentos, contratoEntregue
                  // são mantidos, pois a tela de edição não os altera diretamente.
                });
                await DatabaseHelper().updateGestante(widget.gestante);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // CABEÇALHO ROSA COM FOTO À ESQUERDA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.pink.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.gestante.fotoPath != null 
                      ? _buildImageProvider(widget.gestante.fotoPath!)
                      : null,
                  child: widget.gestante.fotoPath == null 
                    ? const Icon(Icons.person, size: 40, color: Colors.pink) 
                    : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${widget.gestante.semanasHoje}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Maternidade: ${widget.gestante.maternidade}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Risco: ${widget.gestante.classificacaoRisco}',
                        style: TextStyle(
                          color: widget.gestante.classificacaoRisco == 'Alto Risco' 
                            ? Colors.red 
                            : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              // Removido o shrinkWrap e NeverScrollableScrollPhysics para permitir o scroll natural da lista
              itemCount: widget.gestante.ficha.length,
              itemBuilder: (context, index) {
                final cartao = widget.gestante.ficha[index];

                return Dismissible(
                  // Key única para o cartão (Título + ID interno se houver)
                  key: ObjectKey(cartao), 
                  direction: DismissDirection.endToStart, // Arrastar para a esquerda
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Excluir Cartão"),
                        content: Text("Isso apagará o cartão '${cartao.titulo}' e todos os seus itens. Confirmar?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCELAR")),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true), 
                            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red))
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    setState(() {
                      widget.gestante.ficha.removeAt(index);
                    });
                    // Salva a remoção do cartão e seus itens no banco
                    await DatabaseHelper().updateGestante(widget.gestante);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Cartão '${cartao.titulo}' excluído")),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: Checkbox(
                        value: cartao.concluido,
                        activeColor: Colors.green,
                        onChanged: (bool? value) async {
                          setState(() {
                            cartao.concluido = value ?? false;
                            if (cartao.concluido) {
                              for (var sub in cartao.subtopicos) {
                                sub.concluido = true;
                              }
                            }
                          });
                          await DatabaseHelper().updateGestante(widget.gestante);
                        },
                      ),
                      title: Text(
                        cartao.titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: cartao.concluido ? Colors.black : Colors.pink,
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        // LISTA DE ITENS (EXCLUSÃO APENAS PELA LIXEIRA)
                        ...cartao.subtopicos.map((sub) {
                          return ListTile(
                            dense: true,
                            leading: Checkbox(
                              value: sub.concluido,
                              onChanged: (bool? val) async {
                                setState(() {
                                  sub.concluido = val ?? false;
                                  cartao.concluido = cartao.subtopicos.every((s) => s.concluido);
                                });
                                await DatabaseHelper().updateGestante(widget.gestante);
                              },
                            ),
                            title: Text(sub.texto),
                            // O ícone de lixeira aqui exclui apenas o item específico
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () async {
                                setState(() => cartao.subtopicos.remove(sub));
                                await DatabaseHelper().updateGestante(widget.gestante);
                              },
                            ),
                          );
                        }),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextButton.icon(
                            onPressed: () => _exibirDialogoAdicionarItem(cartao),
                            icon: const Icon(Icons.add, size: 18, color: Colors.blue),
                            label: const Text('Adicionar item', style: TextStyle(color: Colors.blue)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarNovoCard,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _adicionarNovoCard() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Cartão'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Título do cartão')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.gestante.ficha.add(CartaoFicha(titulo: controller.text));
                });
                await DatabaseHelper().updateGestante(widget.gestante);
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _editarTituloCard(int index) {
    final controller = TextEditingController(text: widget.gestante.ficha[index].titulo);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Título'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.gestante.ficha[index].titulo = controller.text;
                });
                await DatabaseHelper().updateGestante(widget.gestante);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
void _importarFicha(List<Gestante> todasAsGestantes) {
  final outras = todasAsGestantes.where((g) => g.nome != widget.gestante.nome).toList();

  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Copiar cartões de:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: outras.length,
            itemBuilder: (context, index) {
              final g = outras[index];
              return ListTile(
                leading: const Icon(Icons.copy),
                title: Text(g.nome),
                onTap: () async {
                  setState(() {
                    // FILTRO INTELIGENTE:
                    // Não copia cartões que começam com estas palavras
                    final proibidos = ['Dpp', 'Maternidade', 'Risco'];

                    for (var cartao in g.ficha) {
                      bool ehPessoal = proibidos.any((p) => cartao.titulo.contains(p));
                      
                      if (!ehPessoal) {
                        // Usa o método copiar() que criamos no modelo
                        widget.gestante.ficha.add(cartao.copiar());
                      }
                    }
                  });
                  await DatabaseHelper().updateGestante(widget.gestante);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cartões importados (DPP e Risco ignorados)')),
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

void _exibirDialogoAdicionarItem(CartaoFicha cartao) {
  final TextEditingController itemController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Novo item em: ${cartao.titulo}'),
      content: TextField(
        controller: itemController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Digite o nome do item...'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (itemController.text.isNotEmpty) {
              setState(() {
                cartao.subtopicos.add(Subtopico(texto: itemController.text, concluido: false));
                // Se adicionou item novo, o cartão não pode estar 100% concluído
                cartao.concluido = false;
              });
              await DatabaseHelper().updateGestante(widget.gestante);
              Navigator.pop(context);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}

  //Converter imagem para o database
  ImageProvider? _buildImageProvider(String path) {
    return _imageProviderService.buildImageProvider(path);
  }

}