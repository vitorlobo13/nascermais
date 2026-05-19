import 'package:flutter/material.dart';
import '../models/gestante.dart';
import 'detalhes_pagamento_screen.dart';
 
class FinanceiroScreen extends StatelessWidget {
  final ValueNotifier<List<Gestante>> gestantesNotifier;
  final Future<void> Function() onRefresh;
 
  const FinanceiroScreen({
    super.key,
    required this.gestantesNotifier,
    required this.onRefresh,
  });
 
  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder reconstrói esta tela toda vez que
    // gestantesNotifier.value mudar — sem setState, sem passagem de lista
    return ValueListenableBuilder<List<Gestante>>(
      valueListenable: gestantesNotifier,
      builder: (context, gestantes, _) {
        final double totalContratado = gestantes.fold(0, (s, g) => s + g.valorContrato);
        final double totalRecebido   = gestantes.fold(0, (s, g) => s + g.totalPago);
        final int pendentesEntrega   = gestantes
            .where((g) => g.valorContrato > 0 && !g.contratoEntregue)
            .length;
 
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestão Financeira'),
            backgroundColor: Colors.green.shade100,
          ),
          body: Column(
            children: [
              // RESUMO DO TOPO
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _resumoItem('A Receber', totalContratado - totalRecebido, Colors.red),
                    _resumoItem(
                      'Contratos Pendentes',
                      pendentesEntrega.toDouble(),
                      Colors.orange,
                      isCount: true,
                    ),
                  ],
                ),
              ),
 
              // LISTA DE GESTANTES
              Expanded(
                child: gestantes.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma gestante cadastrada.\nCadastre uma gestante primeiro.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: gestantes.length,
                        itemBuilder: (context, index) {
                          final g = gestantes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                g.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        g.valorContrato == 0
                                            ? Icons.add_circle_outline
                                            : Icons.description,
                                        size: 16,
                                        color: g.valorContrato == 0
                                            ? Colors.grey
                                            : (g.contratoEntregue
                                                ? Colors.green
                                                : Colors.orange),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        g.valorContrato == 0
                                            ? 'Clique para definir contrato'
                                            : (g.contratoEntregue
                                                ? 'Contrato Entregue'
                                                : 'Contrato Pendente'),
                                        style: TextStyle(
                                          color: g.valorContrato == 0
                                              ? Colors.grey
                                              : (g.contratoEntregue
                                                  ? Colors.green
                                                  : Colors.orange),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (g.valorContrato > 0)
                                    Text(
                                      'Pago: R\$ ${g.totalPago.toStringAsFixed(2)}'
                                      ' de R\$ ${g.valorContrato.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalhesPagamentoScreen(gestante: g),
                                  ),
                                );
                                // onRefresh atualiza gestantesNotifier.value no pai,
                                // o ValueListenableBuilder reconstrói automaticamente
                                await onRefresh();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
 
  Widget _resumoItem(String label, double valor, Color cor,
      {bool isCount = false}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(
          isCount
              ? valor.toInt().toString()
              : 'R\$ ${valor.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: cor),
        ),
      ],
    );
  }
}