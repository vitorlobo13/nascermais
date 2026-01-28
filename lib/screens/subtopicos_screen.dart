import 'package:flutter/material.dart';
import '../models/gestante.dart';

class SubtopicosScreen extends StatefulWidget {
  final CartaoFicha cartao;
  const SubtopicosScreen({super.key, required this.cartao});

  @override
  State<SubtopicosScreen> createState() => _SubtopicosScreenState();
}

class _SubtopicosScreenState extends State<SubtopicosScreen> {
  final _controller = TextEditingController();

  void _adicionarSubtopico() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        widget.cartao.subtopicos.add(Subtopico(texto: _controller.text));
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cartao.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Adicionar item (ex: Paracetamol)'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _adicionarSubtopico),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartao.subtopicos.length,
              itemBuilder: (context, index) {
                final item = widget.cartao.subtopicos[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.concluido,
                    onChanged: (val) => setState(() => item.concluido = val!),
                  ),
                  title: Text(item.texto),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => widget.cartao.subtopicos.removeAt(index)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
