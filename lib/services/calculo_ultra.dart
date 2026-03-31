import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CampoCadastroUltra extends StatelessWidget {
  final DateTime? dataUltra;
  final Function(DateTime) onDataSelecionada;
  final Function(String) onSemanasChanged;
  final Function(String) onDiasChanged;
  final Color corFundo;
  final String labelData;

  const CampoCadastroUltra({
    super.key,
    required this.dataUltra,
    required this.onDataSelecionada,
    required this.onSemanasChanged,
    required this.onDiasChanged,
    required this.corFundo,
    required this.labelData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              dataUltra == null 
                  ? labelData 
                  : 'Data da Ultra: ${DateFormat('dd/MM/yyyy').format(dataUltra!)}',
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
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Semanas'),
                  onChanged: onSemanasChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dias'),
                  onChanged: onDiasChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}