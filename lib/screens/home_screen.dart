import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io'; // Adicionado para File
import 'package:flutter/foundation.dart' show kIsWeb; // Adicionado para kIsWeb
import '../models/gestante.dart';
import 'cadastro_screen.dart';
import 'detalhes_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Gestante> gestantes;
  final Function(List<Gestante>) onSave;

  const HomeScreen({
    super.key,
    required this.gestantes,
    required this.onSave,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Gestante> listaGestantes;
  late List<Gestante> listaFiltrada;
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    listaGestantes = widget.gestantes;
    listaFiltrada = listaGestantes;
  }

  void _filtrarGestantes(String query) {
    setState(() {
      listaFiltrada = listaGestantes
          .where((g) => g.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _salvarDados() {
    widget.onSave(listaGestantes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Gestantes'),
        backgroundColor: Colors.pink.shade100,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _buscaController,
              onChanged: _filtrarGestantes,
              decoration: InputDecoration(
                hintText: 'Buscar gestante...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Contador de Gestantes
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total: ${listaFiltrada.length} gestante(s)',
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(child: Text('Nenhuma gestante encontrada.'))
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final g = listaFiltrada[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Excluir Ficha?'),
                              content: Text(
                                  'Deseja realmente excluir a ficha de ${g.nome}?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Excluir',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          setState(() {
                            listaGestantes.remove(g);
                            _filtrarGestantes(_buscaController.text);
                          });
                          _salvarDados();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            // LEADING ATUALIZADO PARA MOSTRAR A FOTO
                            leading: CircleAvatar(
                              backgroundColor: Colors.pink.shade50,
                              backgroundImage: g.fotoPath != null 
                                ? (kIsWeb ? NetworkImage(g.fotoPath!) : FileImage(File(g.fotoPath!)) as ImageProvider)
                                : null,
                              child: g.fotoPath == null 
                                ? const Icon(Icons.person, color: Colors.pink) 
                                : null,
                            ),
                            title: Text(g.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Hoje: ${g.semanasHoje}\nDPP: ${DateFormat('dd/MM/yyyy').format(g.dppFinal)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DetalhesGestanteScreen(gestante: g)),
                            ).then((_) {
                              setState(() {});
                              _salvarDados();
                            }),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nova = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CadastroScreen()));
          if (nova != null) {
            setState(() {
              listaGestantes.add(nova);
              _filtrarGestantes(_buscaController.text);
            });
            _salvarDados();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
