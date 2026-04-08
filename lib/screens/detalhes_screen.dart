import 'package:flutter/material.dart';
import '../models/gestante.dart';
import '../services/image_convert_database.dart';
import '../services/arquiva_gestante.dart';
import '../services/edita_gestante.dart';
import '../services/ficha_service.dart';
import '../services/gerencia_parto.dart';


class DetalhesGestanteScreen extends StatefulWidget {
  final Gestante gestante;
  final List<Gestante> todasAsGestantes;

  const DetalhesGestanteScreen({super.key, required this.gestante, required this.todasAsGestantes});

  @override
  State<DetalhesGestanteScreen> createState() => _DetalhesGestanteScreenState();
}

class _DetalhesGestanteScreenState extends State<DetalhesGestanteScreen> {
  final _imageProviderService = ImageProviderService();
  final _fichaService = FichaService();
  
  void _atualizar() {
    if (mounted) setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //CABEÇALHO
      appBar: AppBar(
        //NOME DA GESTANTE NO TÍTULO
        title: Text(widget.gestante.nome),
        backgroundColor: Colors.pink.shade100,
        actions: [
          // BOTÃO PARA MARCAR PARTO - PÓS-PARTO
          IconButton(
            icon: Icon(
              widget.gestante.jaNasceu ? Icons.pregnant_woman : Icons.child_friendly,
              size: 35.0
            ),
            tooltip: widget.gestante.jaNasceu ? 'Status: Pós-parto' : 'Marcar nascimento',
            onPressed: () => GerenciaParto.executar(
              context: context,
              gestante: widget.gestante,
              setState: setState,
              mounted: mounted,
            ),
          ),

          // BOTÃO PARA IMPORTAR CARTÕES DE OUTRA GESTANTE
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Importar cartões de outra gestante',
            onPressed: () => _fichaService.mostrarImportarFicha(context, widget.gestante, widget.todasAsGestantes, _atualizar),
          ),
          // BOTÃO PARA ARQUIVAR OU DESARQUIVAR GESTANTE
          IconButton(
            icon: Icon(widget.gestante.arquivada ? Icons.unarchive : Icons.archive),
            tooltip: widget.gestante.arquivada ? 'Desarquivar' : 'Arquivar',
            onPressed: () async {
              await ArquivaGestante.executar(
                context: context,
                gestante: widget.gestante,
                setState: setState,
                mounted: mounted,
              );
            },
          ),
          //BOTÃO PARA EDITAR AS INFORMAÇÕES DA GESTANTE
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await EditaGestante.executar(
                context: context,
                gestante: widget.gestante,
                setState: setState,
              );
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
                //BUSCAR A FOTO DA GESTANTE
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
                //INFORMAÇÕES DA GESTANTE QUE FICA AO LADO DA FOTO
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
          
          //EXIBINDO OS CARTÕES/FICHA DA GESTANTE
          Expanded(
            child: ListView.builder(
              itemCount: widget.gestante.ficha.length,
              itemBuilder: (context, index) {
                final cartao = widget.gestante.ficha[index];

                return Dismissible(
                  key: ObjectKey(cartao),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Excluir Cartão"),
                        content: Text("Isso apagará o cartão '${cartao.titulo}' e todos os seus itens. Confirmar?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("CANCELAR")),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final titulo = cartao.titulo;
                    await _fichaService.excluirCartao(widget.gestante, index);
                    if (!mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Cartão '$titulo' excluído")),
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
                          await _fichaService.alternarConclusaoCartao(widget.gestante, cartao, value ?? false);
                          _atualizar();
                        },
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cartao.titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cartao.concluido ? Colors.black : Colors.pink,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                            onPressed: () => _fichaService.mostrarDialogoEditarTitulo(context, widget.gestante, index, _atualizar),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        ...cartao.subtopicos.map((sub) {
                          return ListTile(
                            dense: true,
                            leading: Checkbox(
                              value: sub.concluido,
                              onChanged: (bool? val) async {
                                await _fichaService.alternarConclusaoSubtopico(widget.gestante, cartao, sub, val ?? false);
                                _atualizar();
                              },
                            ),
                            title: Text(sub.texto),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () async {
                                await _fichaService.excluirSubtopico(widget.gestante, cartao, sub);
                                _atualizar();
                              },
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextButton.icon(
                            onPressed: () => _fichaService.mostrarDialogoAdicionarItem(context, widget.gestante, cartao, _atualizar),
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
      // BOTÃO + PARA ADICIONAR NOVA FICHA/CARTAO
      floatingActionButton: FloatingActionButton(
        onPressed: () => _fichaService.mostrarDialogoNovoCartao(context, widget.gestante, _atualizar),
        child: const Icon(Icons.add),
      ),
    );
  }

  //Converter imagem do database para exibir
  ImageProvider? _buildImageProvider(String path) {
    return _imageProviderService.buildImageProvider(path);
  }

}
