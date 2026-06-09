import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gestante.dart';
import '../services/notification_service.dart';
import '../services/gestantes_provider.dart';

class DetalhesPagamentoScreen extends StatefulWidget {
  final Gestante gestante;
  const DetalhesPagamentoScreen({super.key, required this.gestante});

  @override
  State<DetalhesPagamentoScreen> createState() => _DetalhesPagamentoScreenState();
}

class _DetalhesPagamentoScreenState extends State<DetalhesPagamentoScreen> {
  late TextEditingController _valorContratoController;
  late TextEditingController _diaVencimentoController;
  final _valorPagamentoController = TextEditingController();
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _valorContratoController = TextEditingController(text: widget.gestante.valorContrato.toString());
    _diaVencimentoController = TextEditingController(
      text: widget.gestante.diaVencimento?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _valorContratoController.dispose();
    _diaVencimentoController.dispose();
    _valorPagamentoController.dispose();
    super.dispose();
  }

  /// Centraliza a atualização da UI e das notificações
  Future<void> _sincronizarDados() async {
    setState(() {}); 
    _notificationService.atualizarLembrete(widget.gestante);
    
    // SALVAR NO PROVEDOR DE ESTADO (que persiste no banco)
    GestantesStateScope.of(context, listen: false).atualizarGestante(widget.gestante);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gestante;
    return Scaffold(
      appBar: AppBar(
        title: Text('Financeiro: ${g.nome}'), 
        backgroundColor: Colors.green.shade100
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEÇÃO 1: CONTRATO E VENCIMENTO
            const Text('Dados do Contrato', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _valorContratoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor Total (R\$)', 
                      border: OutlineInputBorder()
                    ),
                    onChanged: (val) async {
                      g.valorContrato = double.tryParse(val) ?? 0.0;
                      await _sincronizarDados();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _diaVencimentoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dia Venc.', 
                      hintText: '1-31',
                      border: OutlineInputBorder()
                    ),
                    onChanged: (val) async {
                      int? dia = int.tryParse(val);
                      if (dia != null && dia >= 1 && dia <= 31) {
                        g.diaVencimento = dia;
                      } else if (val.isEmpty) {
                        g.diaVencimento = null;
                      }
                      await _sincronizarDados();
                    },
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contrato Entregue?'),
              value: g.contratoEntregue,
              onChanged: (val) async {
                setState(() => g.contratoEntregue = val ?? false);
                await _sincronizarDados();
                // Opcional: Salvar no banco aqui
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 40),

            // SEÇÃO 2: RESUMO FINANCEIRO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _resumoMini('Total', g.valorContrato, Colors.blue),
                  _resumoMini('Pago', g.totalPago, Colors.green),
                  _resumoMini('Saldo', g.saldoDevedor, g.saldoDevedor > 0 ? Colors.red : Colors.grey),
                ],
              ),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Valor R\$', 
                      border: OutlineInputBorder()
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    String textoFormatado = _valorPagamentoController.text.replaceAll(',', '.');
                    double? v = double.tryParse(textoFormatado);
                    if (v != null && v > 0) {
                      g.pagamentos.add(Pagamento(
                        valor: v, 
                        data: DateTime.now(), 
                        descricao: 'Parcela'
                      ));
                      _valorPagamentoController.clear();
                      await _sincronizarDados(); // Cancela notificação se o saldo zerar
                    }
                  },
                  child: const Text('Adicionar'),
                )
              ],
            ),
            const SizedBox(height: 20),

            // LISTA DE PAGAMENTOS
            const Text('Histórico de Pagamentos', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: g.pagamentos.length,
              itemBuilder: (context, index) {
                final p = g.pagamentos[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.attach_money, color: Colors.white, size: 20),
                  ),
                  title: Text('R\$ ${p.valor.toStringAsFixed(2)}'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(p.data)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red), 
                    onPressed: () async {
                      g.pagamentos.removeAt(index);
                      await _sincronizarDados(); // Reativa notificação se voltar a ter saldo
                    }
                  ),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}', 
          style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 16)
        ),
      ],
    );
  }
}