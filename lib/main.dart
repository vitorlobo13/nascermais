import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/financeiro_screen.dart';
import 'screens/ajustes_screen.dart'; // Import da nova tela
import 'models/gestante.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const DoulaApp());
}

class DoulaApp extends StatelessWidget {
  const DoulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doula Admin',
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

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gestantesJson = prefs.getString('lista_gestantes');
    if (gestantesJson != null) {
      final List<dynamic> listaDecodificada = jsonDecode(gestantesJson);
      setState(() {
        listaGestantes = listaDecodificada
            .map((item) => Gestante.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _salvarDados(List<Gestante> gestantes) async {
    final prefs = await SharedPreferences.getInstance();
    final String gestantesJson =
        jsonEncode(gestantes.map((g) => g.toJson()).toList());
    await prefs.setString('lista_gestantes', gestantesJson);
    setState(() {
      listaGestantes = gestantes;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lista de telas atualizada com a AjustesScreen
    final List<Widget> telas = [
      HomeScreen(
        gestantes: listaGestantes,
        onSave: _salvarDados,
      ),
      FinanceiroScreen(
        gestantes: listaGestantes,
        onSave: _salvarDados,
      ),
      const AjustesScreen(), // Nova tela de Ajuda e Feedback
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
        // Adicionado o terceiro item na barra de navegação
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Gestantes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Financeiro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
