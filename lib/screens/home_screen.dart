import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gestante.dart';
import 'cadastro_screen.dart';
import 'detalhes_screen.dart';
import '../services/image_convert_database.dart';
import '../services/gestantes_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  final _imageProviderService = ImageProviderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = GestantesStateScope.of(context);
    final gestantes = provider.gestantes;

    final query = _buscaController.text;
    final bool mostrarArquivadas = _tabController.index == 1;

    // Filtra e ordena as gestantes de forma reativa
    final gestantesFiltradas = gestantes.where((g) {
      final matchesQuery = g.nome.toLowerCase().contains(query.toLowerCase());
      final matchesStatus = g.arquivada == mostrarArquivadas;
      return matchesQuery && matchesStatus;
    }).toList();

    gestantesFiltradas.sort((a, b) => a.dppFinal.compareTo(b.dppFinal));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nascer+', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink,
          tabs: const [
            Tab(icon: Icon(Icons.pregnant_woman), text: 'Ativas'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Arquivadas'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Camada 1: Marca d'água de fundo
          Center(
            child: Opacity(
              opacity: 0.1, 
              child: Image.asset(
                'assets/images/nascermaisicon.png',
                colorBlendMode: BlendMode.srcIn,
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ), 
          // Camada 2: Conteúdo
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar gestante...',
                    prefixIcon: const Icon(Icons.search, color: Colors.pink),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.pink.shade50.withOpacity(0.5),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: gestantesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 80, color: Colors.pink.shade100),
                            const SizedBox(height: 16),
                            Text(
                              _tabController.index == 0 ? 'Nenhuma gestante ativa.' : 'Nenhuma gestante arquivada.',
                              style: TextStyle(fontSize: 16, color: Colors.pink.shade300),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: gestantesFiltradas.length,
                        itemBuilder: (context, index) {
                          final g = gestantesFiltradas[index];
                          final bool isArquivada = g.arquivada;
                          final Color cardColor = isArquivada ? Colors.grey.shade100 : Colors.white;
                          final Color textColor = isArquivada ? Colors.grey.shade600 : Colors.black87;
                          final Color subtextColor = isArquivada ? Colors.grey.shade400 : Colors.pink.shade400;

                          return Dismissible(
                            key: Key(g.id?.toString() ?? g.nome + index.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Excluir Registro?'),
                                  content: Text('Deseja excluir permanentemente os dados de ${g.nome}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              await provider.excluirGestante(g);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Dados de ${g.nome} excluídos.')),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: isArquivada ? 0 : 2,
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: isArquivada ? Colors.grey.shade300 : Colors.pink.shade50),
                              ),
                              child: Opacity(
                                opacity: isArquivada ? 0.7 : 1.0,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: isArquivada ? Colors.grey.shade400 : Colors.pink.shade100,
                                    backgroundImage: (g.fotoPath != null && g.fotoPath!.isNotEmpty)
                                        ? _buildImageProvider(g.fotoPath!)
                                        : null,
                                    child: (g.fotoPath == null || g.fotoPath!.isEmpty)
                                        ? Text(
                                            g.nome[0].toUpperCase(),
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    g.nome, 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        isArquivada ? 'Registro Arquivado' : g.semanasHoje, 
                                        style: TextStyle(color: subtextColor, fontWeight: FontWeight.w500)
                                      ),
                                      Text(
                                        'DPP: ${DateFormat('dd/MM/yyyy').format(g.dppFinal)}', 
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(Icons.chevron_right, color: isArquivada ? Colors.grey.shade300 : Colors.pink.shade200),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetalhesGestanteScreen(
                                          gestante: g, 
                                        ),
                                      ),
                                    );
                                    // Após retornar dos detalhes, garante a recarga dos dados
                                    provider.carregarGestantes();
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroScreen()),
          );
          if (result != null && result is Gestante) {
            // Recarrega todos os dados do banco para garantir consistência
            await provider.carregarGestantes();
          }
        },
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Gestante', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  ImageProvider? _buildImageProvider(String path) {
    return _imageProviderService.buildImageProvider(path);
  }
}