import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gestante.dart';

class DetalhesPagamentoScreen extends StatefulWidget {
  final Gestante gestante;
  const DetalhesPagamentoScreen({super.key, required this.gestante});

  @override
  State<DetalhesPagamentoScreen> createState() => _DetalhesPagamentoScreenState();
}

class _DetalhesPagamentoScreenState extends State<DetalhesPagamentoScreen> {
  late TextEditingController _valorContratoController;
  final _valorPagamentoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _valorContratoController = TextEditingController(text: widget.gestante.valorContrato.toString());
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gestante;
    return Scaffold(
      appBar: AppBar(title: Text('Financeiro: ${g.nome}'), backgroundColor: Colors.green.shade100),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEÇÃO 1: CONTRATO
            const Text('Dados do Contrato', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorContratoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor Total do Contrato (R\$)', border: OutlineInputBorder()),
                    onChanged: (val) => setState(() => g.valorContrato = double.tryParse(val) ?? 0.0),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('Contrato Entregue?'),
              value: g.contratoEntregue,
              onChanged: (val) => setState(() => g.contratoEntregue = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 40),

            // SEÇÃO 2: RESUMO FINANCEIRO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _resumoMini('Total', g.valorContrato, Colors.blue),
                _resumoMini('Pago', g.totalPago, Colors.green),
                _resumoMini('Saldo', g.saldoDevedor, Colors.red),
              ],
            ),
            const Divider(height: 40),

            // SEÇÃO 3: REGISTRAR PAGAMENTO
            const Text('Registrar Pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorPagamentoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Valor R\$', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    double? v = double.tryParse(_valorPagamentoController.text);
                    if (v != null && v > 0) {
                      setState(() {
                        g.pagamentos.add(Pagamento(valor: v, data: DateTime.now(), descricao: 'Parcela'));
                        _valorPagamentoController.clear();
                      });
                    }
                  },
                  child: const Text('Adicionar'),
                )
              ],
            ),
            const SizedBox(height: 20),

            // LISTA DE PAGAMENTOS JÁ FEITOS
            const Text('Histórico de Pagamentos', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: g.pagamentos.length,
              itemBuilder: (context, index) {
                final p = g.pagamentos[index];
                return ListTile(
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: Text('R\$ ${p.valor.toStringAsFixed(2)}'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(p.data)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), 
                    onPressed: () => setState(() => g.pagamentos.removeAt(index))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumoMini(String label, double valor, Color cor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text('R\$ ${valor.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 16)),
      ],
    );
  }
}
