import 'package:flutter/material.dart';
import '../models/gestante.dart';
import '../services/database_helper.dart';

class ArquivaGestante {
  /// Executa o processo de alternar o status de arquivamento, 
  /// salva no banco e retorna para a tela anterior.
  static Future<void> executar({
    required BuildContext context,
    required Gestante gestante,
    required Function(VoidCallback fn) setState,
    required bool mounted,
  }) async {
    
    // 1. Inverte o status de arquivamento (Lógica de Estado)
    setState(() {
      gestante.arquivada = !gestante.arquivada;
    });

    // 2. Salva no Banco de Dados através do Singleton DatabaseHelper
    await DatabaseHelper().updateGestante(gestante);

    // 3. Segurança: verifica se o widget ainda está na árvore de elementos
    if (!mounted) return;

    // 4. Feedback visual (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          gestante.arquivada ? 'Gestante arquivada!' : 'Gestante reativada!',
        ),
      ),
    );

    // 5. Retorna para a tela anterior (Home) com os dados atualizados
    Navigator.pop(context, gestante);
  }
}