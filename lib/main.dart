import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/financeiro_screen.dart';
import 'screens/ajustes_screen.dart';
import 'models/gestante.dart';
import 'services/database_helper.dart'; // Import do nosso novo serviço

void main() {
  // Garante que os plugins (como o SQLite) sejam inicializados antes do app rodar
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
  List<Gestante> listaGestantes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instância do banco

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Carrega os dados do SQLite em vez do SharedPreferences
  Future<void> _carregarDados() async {
    final dados = await _dbHelper.getGestantes();
    setState(() {
      listaGestantes = dados;
    });
  }

  // Função para salvar (Insert ou Update)
  Future<void> _salvarDados(List<Gestante> gestantes) async {
    // Como agora o banco gerencia cada item individualmente, 
    // esta função no main.dart servirá apenas para atualizar a UI local.
    // O salvamento real será feito nas telas de Cadastro e Edição.
    setState(() {
      listaGestantes = gestantes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      HomeScreen(
        gestantes: listaGestantes,
        onSave: _salvarDados,
      ),
      FinanceiroScreen(
        gestantes: listaGestantes,
        onSave: _salvarDados,
      ),
      const AjustesScreen(),
    ];

    return Scaffold(
      body: telas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
