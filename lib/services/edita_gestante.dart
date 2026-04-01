import 'package:flutter/material.dart';
import '../models/gestante.dart';
import '../services/database_helper.dart';
import '../screens/editar_gestante_screen.dart';

class EditaGestante {
  static Future<void> executar({
    required BuildContext context,
    required Gestante gestante,
    required Function(VoidCallback fn) setState,
  }) async {
    
    // 1. Navega para a tela editar_gestante_screen
    final Gestante? atualizada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarGestanteScreen(gestante: gestante),
      ),
    );

    // 2. Se o usuário salvou e retornou uma gestante nova
    if (atualizada != null) {
      setState(() {
        // Sincroniza o objeto original com os novos dados
        // Como objetos em Dart são passados por referência, 
        // atualizar as propriedades aqui reflete em todo o app.
        gestante.nome = atualizada.nome;
        gestante.dppFinal = atualizada.dppFinal;
        gestante.maternidade = atualizada.maternidade;
        gestante.classificacaoRisco = atualizada.classificacaoRisco;
        gestante.fotoPath = atualizada.fotoPath;
        gestante.ficha = atualizada.ficha;
        // Campos que não mudam na edição,por enquanto, mas devem ser mantidos
        gestante.valorContrato = atualizada.valorContrato;
        gestante.pagamentos = atualizada.pagamentos;
        gestante.contratoEntregue = atualizada.contratoEntregue;
      });

      // 3. Persiste no Banco de Dados
      await DatabaseHelper().updateGestante(gestante);
    }
  }
}