import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/financeiro_screen.dart';
import 'screens/ajustes_screen.dart';
import 'models/gestante.dart';
import 'services/database_helper.dart';
 
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NascerMais());
}
 
class NascerMais extends StatelessWidget {
  const NascerMais({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nascer+',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}
 
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
 
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}
 
class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
 
  // ValueNotifier: dispara rebuild reativo em todos os filhos que o escutam
  final ValueNotifier<List<Gestante>> gestantesNotifier = ValueNotifier([]);
 
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
 
  @override
  void dispose() {
    gestantesNotifier.dispose();
    super.dispose();
  }
 
  Future<void> _carregarDados() async {
    final dados = await _dbHelper.getGestantes();
    // Atribuir ao notifier já dispara o rebuild nos filhos automaticamente
    gestantesNotifier.value = dados;
  }
 
  Future<void> _salvarDados(List<Gestante> gestantes) async {
    for (final g in gestantes) {
      if (g.id != null) {
        await _dbHelper.updateGestante(g);
      } else {
        final novoId = await _dbHelper.insertGestante(g);
        g.id = novoId;
      }
    }
    await _carregarDados();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            gestantesNotifier: gestantesNotifier,
            onSave: _salvarDados,
            onRefresh: _carregarDados,
          ),
          FinanceiroScreen(
            gestantesNotifier: gestantesNotifier,
            onRefresh: _carregarDados,
          ),
          const AjustesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          await _carregarDados();
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Gestantes'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Financeiro'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}