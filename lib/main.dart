import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/financeiro_screen.dart';
import 'screens/ajustes_screen.dart';
import 'services/notification_service.dart';
import 'services/gestantes_provider.dart';

void main() async {
  // Garante que os plugins (como o SQLite) sejam inicializados antes do app rodar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa notificações locais
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.solicitarPermissoes();
  
  runApp(const NascerMais());
}

class NascerMais extends StatefulWidget {
  const NascerMais({super.key});

  @override
  State<NascerMais> createState() => _NascerMaisState();
}

class _NascerMaisState extends State<NascerMais> {
  final GestantesProvider _provider = GestantesProvider();

  @override
  void initState() {
    super.initState();
    _provider.carregarGestantes();
  }

  @override
  Widget build(BuildContext context) {
    return GestantesStateScope(
      notifier: _provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nascer+',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
      ),
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      const HomeScreen(),
      const FinanceiroScreen(),
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
