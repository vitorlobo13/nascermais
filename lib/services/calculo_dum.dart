import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CampoDataDUM extends StatelessWidget {
  final DateTime? dataSelecionada;
  final Function(DateTime) onDataSelecionada;
  final String labelPadrao; 
  final String prefixoTexto;
  final Color corFundo;

  const CampoDataDUM({
    super.key,
    required this.dataSelecionada,
    required this.onDataSelecionada,
    required this.labelPadrao,
    required this.prefixoTexto,
    required this.corFundo,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: corFundo,
      title: Text(
        dataSelecionada == null
            ? labelPadrao
            : '$prefixoTexto${DateFormat('dd/MM/yyyy').format(dataSelecionada!)}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 300)),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          onDataSelecionada(picked);
        }
      },
    );
  }
}