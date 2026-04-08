import 'package:flutter/material.dart';
import '../models/gestante.dart';
import 'database_helper.dart';

class GerenciaParto {
  static Future<void> executar({
    required BuildContext context,
    required Gestante gestante,
    required Function setState,
    required bool mounted,
  }) async {
    final bool jaNasceu = gestante.jaNasceu;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jaNasceu ? 'Reverter Status' : 'Confirmar Nascimento'),
        content: Text(jaNasceu
            ? 'Deseja voltar o status para "Em gestação"?'
            : 'Ao confirmar, o status da gestante mudará para "Pós-parto". Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // 1. Atualiza o estado local
      setState(() {
        gestante.jaNasceu = !jaNasceu;
      });

      // 2. Persiste no banco de dados
      await DatabaseHelper().updateGestante(gestante);

      // 3. Feedback para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(gestante.jaNasceu
                ? 'Status alterado para Pós-parto!'
                : 'Status revertido para Gestação.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}