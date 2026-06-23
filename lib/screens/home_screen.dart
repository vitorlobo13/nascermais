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
  int? _selectedMonth;

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

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.pink,
        body: Container(
          color: Colors.pink,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo centralizada
                Center(
                  child: Image.asset(
                    'assets/images/nascermaisicon.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                // Indicador de carregamento
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const Spacer(),
                // Frase desenvolvida com carinho
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
                  child: Text(
                    'Desenvolvido com ❤️ para quem vive o nascer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final gestantes = provider.gestantes;
    final agora = DateTime.now();
    final totalGestantesAtivas = gestantes.where((g) => !g.arquivada).length;
    final partosEsteMes = gestantes.where((g) {
      return !g.arquivada && g.dppFinal.month == agora.month && g.dppFinal.year == agora.year;
    }).length;

    // Calcula os partos previstos por mês (apenas gestantes ativas)
    final Map<int, int> partosPorMes = {};
    for (var g in gestantes) {
      if (!g.arquivada) {
        final m = g.dppFinal.month;
        partosPorMes[m] = (partosPorMes[m] ?? 0) + 1;
      }
    }

    // Define os textos e valores dinâmicos do segundo card baseados no filtro de mês
    final String labelPartosMesa;
    final int contagemPartosMesa;
    if (_selectedMonth == null) {
      labelPartosMesa = 'Partos este mês';
      contagemPartosMesa = partosEsteMes;
    } else {
      const nomesMesesCompletos = [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
      ];
      final nomeMes = nomesMesesCompletos[_selectedMonth! - 1];
      labelPartosMesa = 'Partos em $nomeMes';
      contagemPartosMesa = partosPorMes[_selectedMonth!] ?? 0;
    }

    final query = _buscaController.text;
    final bool mostrarArquivadas = _tabController.index == 1;

    // Filtra e ordena as gestantes de forma reativa
    final gestantesFiltradas = gestantes.where((g) {
      final matchesQuery = g.nome.toLowerCase().contains(query.toLowerCase());
      final matchesStatus = g.arquivada == mostrarArquivadas;
      final matchesMonth = _selectedMonth == null || g.dppFinal.month == _selectedMonth;
      return matchesQuery && matchesStatus && matchesMonth;
    }).toList();

    gestantesFiltradas.sort((a, b) => a.dppFinal.compareTo(b.dppFinal));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nascer+', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(134.0),
          child: Column(
            children: [
              // CARD DE RESUMO (Total de Gestantes e Partos este mês)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Total de Gestantes
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.pregnant_woman_outlined,
                              color: Colors.pink,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total de Gestantes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalGestantesAtivas',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006870),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Linha divisória vertical
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade200,
                      ),
                      // Partos do mês selecionado
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.pink,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labelPartosMesa,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$contagemPartosMesa',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006870),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabController,
                labelColor: Colors.pink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.pink,
                tabs: const [
                  Tab(icon: Icon(Icons.pregnant_woman), text: 'Ativas'),
                  Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Arquivadas'),
                ],
              ),
            ],
          ),
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
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_buscaController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                            onPressed: () {
                              _buscaController.clear();
                              setState(() {});
                            },
                          ),
                        if (_selectedMonth != null) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMonth = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100.withAlpha(153),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    const ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'][_selectedMonth! - 1],
                                    style: const TextStyle(
                                      color: Colors.pink,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.close, size: 14, color: Colors.pink),
                                ],
                              ),
                            ),
                          ),
                        ],
                        PopupMenuButton<int?>(
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: _selectedMonth != null ? Colors.pink : Colors.grey,
                          ),
                          tooltip: 'Filtrar por mês de DPP',
                          onSelected: (int? month) {
                            setState(() {
                              _selectedMonth = month;
                            });
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<int?>(
                              value: null,
                              child: Text('Todos os meses'),
                            ),
                            ...List.generate(12, (index) {
                              final monthIndex = index + 1;
                              const nomesMesesCompletos = [
                                'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                                'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
                              ];
                              final count = partosPorMes[monthIndex] ?? 0;
                              final label = count > 0 
                                  ? '${nomesMesesCompletos[index]} ($count)' 
                                  : nomesMesesCompletos[index];
                              return PopupMenuItem<int?>(
                                value: monthIndex,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: _selectedMonth == monthIndex ? Colors.pink : Colors.black87,
                                    fontWeight: _selectedMonth == monthIndex ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.pink.shade50.withAlpha(128),
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
                          final imageProvider = (g.fotoPath != null && g.fotoPath!.isNotEmpty)
                              ? _buildImageProvider(g.fotoPath!)
                              : null;

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
                              if (!context.mounted) return;
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
                                    child: ClipOval(
                                      child: imageProvider != null
                                          ? Image(
                                              image: imageProvider,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                debugPrint("Erro ao carregar imagem no HomeScreen (${g.nome}): $error");
                                                return Text(
                                                  g.nome[0].toUpperCase(),
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                                );
                                              },
                                            )
                                          : Text(
                                              g.nome[0].toUpperCase(),
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                    ),
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
                                        g.semanasHoje, 
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