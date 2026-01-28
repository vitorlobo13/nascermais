import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/gestante.dart';
import 'subtopicos_screen.dart';

class DetalhesGestanteScreen extends StatefulWidget {
  final Gestante gestante;

  const DetalhesGestanteScreen({super.key, required this.gestante});

  @override
  State<DetalhesGestanteScreen> createState() => _DetalhesGestanteScreenState();
}

class _DetalhesGestanteScreenState extends State<DetalhesGestanteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gestante.nome),
        backgroundColor: Colors.pink.shade100,
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
                    ? (kIsWeb ? NetworkImage(widget.gestante.fotoPath!) : FileImage(File(widget.gestante.fotoPath!)) as ImageProvider)
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
              itemCount: widget.gestante.ficha.length,
              itemBuilder: (context, index) {
                final card = widget.gestante.ficha[index];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      widget.gestante.ficha.removeAt(index);
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          card.concluido ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: card.concluido ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            card.concluido = !card.concluido;
                          });
                        },
                      ),
                      title: Text(
                        card.titulo,
                        style: const TextStyle(
                          // TEXTO SEMPRE PRETO E SEM RISCO (Conforme solicitado)
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          _editarTituloCard(index);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubtopicosScreen(cartao: card),
                          ),
                        ).then((_) => setState(() {}));
                      },
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
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.gestante.ficha.add(CartaoFicha(titulo: controller.text));
                });
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
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.gestante.ficha[index].titulo = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
