import 'package:flutter/material.dart';
import '../models/gestante.dart';
import 'database_helper.dart';

class GestantesProvider extends ChangeNotifier {
  List<Gestante> _gestantes = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Gestante> get gestantes => _gestantes;
  bool get isLoading => _isLoading;

  Future<void> carregarGestantes() async {
    _isLoading = true;
    notifyListeners();
    _gestantes = await _dbHelper.getGestantes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> adicionarGestante(Gestante gestante) async {
    final id = await _dbHelper.insertGestante(gestante);
    gestante.id = id;
    _gestantes.add(gestante);
    notifyListeners();
  }

  Future<void> atualizarGestante(Gestante gestante) async {
    await _dbHelper.updateGestante(gestante);
    final index = _gestantes.indexWhere((g) => g.id == gestante.id);
    if (index != -1) {
      _gestantes[index] = gestante;
    }
    notifyListeners();
  }

  Future<void> excluirGestante(Gestante gestante) async {
    if (gestante.id != null) {
      await _dbHelper.deleteGestante(gestante.id!);
      _gestantes.removeWhere((g) => g.id == gestante.id);
      notifyListeners();
    }
  }
}

class GestantesStateScope extends InheritedNotifier<GestantesProvider> {
  const GestantesStateScope({
    super.key,
    required GestantesProvider super.notifier,
    required super.child,
  });

  static GestantesProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<GestantesStateScope>();
      assert(scope != null, 'Nenhum GestantesStateScope encontrado no contexto');
      return scope!.notifier!;
    } else {
      final scope = context.getElementForInheritedWidgetOfExactType<GestantesStateScope>()?.widget as GestantesStateScope?;
      assert(scope != null, 'Nenhum GestantesStateScope encontrado no contexto');
      return scope!.notifier!;
    }
  }
}
