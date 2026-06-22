import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/financeiro_screen.dart';
import 'screens/ajustes_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/gestantes_provider.dart';
import 'firebase_options.dart';

void main() async {
  // Garante que os plugins sejam inicializados antes do app rodar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Inicialização do Firebase ignorada ou falhou: $e");
  }

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
        // Roteamento: se o Firebase estiver desativado, vai direto para a navegação principal (usando SQLite local)
        home: !GestantesProvider.usarFirebase
            ? const MainNavigation()
            : StreamBuilder<User?>(
                stream: _provider.authStateChanges,
                builder: (context, snapshot) {
                  // Estado de carregamento do Firebase Auth
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(color: Colors.pink),
                      ),
                    );
                  }

                  // Se o usuário está autenticado, navega para o app principal
                  if (snapshot.hasData && snapshot.data != null) {
                    return const MainNavigation();
                  }

                  // Se não está autenticado, exibe a tela de login estilo Glassmorphism
                  return const LoginScreen();
                },
              ),
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
  void initState() {
    super.initState();
    // Carrega as gestantes do Firestore associadas ao usuário logado assim que a navegação inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GestantesStateScope.of(context, listen: false).carregarGestantes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      const HomeScreen(),
      const FinanceiroScreen(),
      const AjustesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: telas,
      ),
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
