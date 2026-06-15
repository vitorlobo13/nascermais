import 'package:flutter/material.dart';
import 'detalhes_pagamento_screen.dart';
import '../services/gestantes_provider.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  bool _mostrarQuitados = false;

  @override
  Widget build(BuildContext context) {
    final provider = GestantesStateScope.of(context);

    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestão Financeira'),
          backgroundColor: Colors.green.shade100,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    final gestantes = provider.gestantes;

    // Calculos para o resumo do topo (considerando todas as gestantes)
    double totalContratado = gestantes.fold(0, (s, g) => s + g.valorContrato);
    double totalRecebido = gestantes.fold(0, (s, g) => s + g.totalPago);
    int pendentesEntrega = gestantes.where((g) => g.valorContrato > 0 && !g.contratoEntregue).length;

    final gestantesExibidas = gestantes.where((g) {
      if (_mostrarQuitados) return true;
      return g.valorContrato == 0 || g.saldoDevedor > 0;
    }).toList();

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
                _resumoItem('Contratos Pendentes', pendentesEntrega.toDouble(), Colors.orange, isCount: true),
              ],
            ),
          ),
          // FILTRO PARA OCULTAR/MOSTRAR QUITADAS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lista de Contratos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Row(
                  children: [
                    const Text('Mostrar quitados', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(width: 4),
                    Switch(
                      value: _mostrarQuitados,
                      activeTrackColor: Colors.green.shade200,
                      activeThumbColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _mostrarQuitados = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // LISTA DE GESTANTES FILTRADAS
          Expanded(
            child: gestantes.isEmpty
                ? const Center(child: Text('Nenhuma gestante cadastrada.\nCadastre uma gestante primeiro.', textAlign: TextAlign.center))
                : gestantesExibidas.isEmpty
                    ? const Center(child: Text('Todos os contratos estão quitados! 🎉\nHabilite "Mostrar quitados" para ver o histórico.', textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: gestantesExibidas.length,
                        itemBuilder: (context, index) {
                          final g = gestantesExibidas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(g.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    g.valorContrato == 0 ? Icons.add_circle_outline : Icons.description, 
                                    size: 16, 
                                    color: g.valorContrato == 0 ? Colors.grey : (g.contratoEntregue ? Colors.green : Colors.orange)
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    g.valorContrato == 0 ? 'Clique para definir contrato' : (g.contratoEntregue ? 'Contrato Entregue' : 'Contrato Pendente'),
                                    style: TextStyle(
                                      color: g.valorContrato == 0 ? Colors.grey : (g.contratoEntregue ? Colors.green : Colors.orange), 
                                      fontSize: 12
                                    )
                                  ),
                                ],
                              ),
                              if (g.valorContrato > 0)
                                Text('Pago: R\$ ${g.totalPago.toStringAsFixed(2)} de R\$ ${g.valorContrato.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13)),
                              if (g.valorContrato > 0)
                                if (g.diaVencimento != null)
                                    Text('Dia do vencimento: ${g.diaVencimento}',
                                        style: const TextStyle(fontSize: 13))
                                  else
                                    Text('Dia do vencimento: Não definido',
                                        style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DetalhesPagamentoScreen(gestante: g)),
                          ).then((_) {
                            // Atualiza os dados a partir do banco de dados ao voltar
                            provider.carregarGestantes();
                          }),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _resumoItem(String label, double valor, Color cor, {bool isCount = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(isCount ? valor.toInt().toString() : 'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
      ],
    );
  }
}
