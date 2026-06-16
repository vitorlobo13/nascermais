import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detalhes_pagamento_screen.dart';
import '../services/gestantes_provider.dart';
import '../services/image_convert_database.dart';
import '../models/gestante.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  bool _mostrarQuitados = false;
  final TextEditingController _buscaController = TextEditingController();
  final _imageProviderService = ImageProviderService();
  final _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = GestantesStateScope.of(context);

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF007D87),
          ),
        ),
      );
    }

    final gestantes = provider.gestantes;

    // Calculos para o resumo do topo (considerando todas as gestantes)
    double totalContratado = gestantes.fold(0, (s, g) => s + g.valorContrato);
    double totalRecebido = gestantes.fold(0, (s, g) => s + g.totalPago);
    int pendentesEntrega = gestantes.where((g) => g.valorContrato > 0 && !g.contratoEntregue).length;

    final query = _buscaController.text.toLowerCase();
    final gestantesExibidas = gestantes.where((g) {
      final matchesQuery = g.nome.toLowerCase().contains(query);
      if (_mostrarQuitados) return matchesQuery;
      return matchesQuery && (g.valorContrato == 0 || g.saldoDevedor > 0);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // HEADER COM ONDULAÇÃO E LOGO ENCAIXADA
          Stack(
            children: [
              ClipPath(
                clipper: HeaderWaveClipper(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF006870), // Teal escuro
                        Color(0xFF00838F), // Teal claro
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gestão Financeira',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acompanhe seus contratos e recebimentos',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // LOGO DO APP ENCAIXADA E ARREDONDADA
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: Image.asset(
                        'assets/images/nascermaisicon_login.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // CARDS DE SUMÁRIO DO TOPO (A RECEBER E PENDENTES)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // Card A Receber
                Expanded(
                  child: Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.03),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFFF2FBFC), // Fundo azul claro
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD3EAEB), // Fundo do ícone
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF007D87), size: 22),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A Receber',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _currencyFormat.format(totalContratado - totalRecebido),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF007D87),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total a receber',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Card Contratos Pendentes
                Expanded(
                  child: Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.03),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFFFDF3F5), // Fundo rosa claro
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9DCE2), // Fundo do ícone
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_outlined, color: Color(0xFFE91E63), size: 22),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contratos Pendentes',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$pendentesEntrega',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Aguardando entrega',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CAMPO DE BUSCA E MOSTRAR QUITADOS NA MESMA LINHA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      controller: _buscaController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar contrato ou gestante...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.teal.shade200, width: 1),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mostrar Quitados',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _mostrarQuitados,
                        activeTrackColor: Colors.green.shade200,
                        activeThumbColor: Colors.green,
                        onChanged: (value) {
                          setState(() {
                            _mostrarQuitados = value;
                          });
                        },
                      ),
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
                    ? const Center(child: Text('Nenhuma gestante ou contrato encontrado.', textAlign: TextAlign.center))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemCount: gestantesExibidas.length,
                        itemBuilder: (context, index) {
                          final g = gestantesExibidas[index];
                          final isQuitada = g.valorContrato > 0 && g.saldoDevedor <= 0;
                          
                          double progresso = g.valorContrato > 0 ? (g.totalPago / g.valorContrato) : 0.0;
                          if (progresso > 1.0) progresso = 1.0;
                          final percentValue = (progresso * 100).toInt();

                          Widget percentBadge;
                          if (percentValue == 100) {
                            percentBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007D87),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '100%',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            );
                          } else {
                            percentBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$percentValue%',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink.shade400),
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade100, width: 1),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetalhesPagamentoScreen(gestante: g)),
                              ).then((_) {
                                provider.carregarGestantes();
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar styled like image
                                        _buildAvatar(g),
                                        const SizedBox(width: 12),
                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                g.nome,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                              ),
                                              const SizedBox(height: 4),
                                              _buildStatusChip(g),
                                              const SizedBox(height: 6),
                                              Text(
                                                'R\$ ${g.totalPago.toStringAsFixed(2)} de R\$ ${g.valorContrato.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Vencimento Info
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Vencimento',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _obterDataVencimento(g),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF007D87),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                      ],
                                    ),
                                    if (g.valorContrato > 0) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progresso,
                                                minHeight: 6,
                                                backgroundColor: Colors.grey.shade100,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  isQuitada ? const Color(0xFF007D87) : Colors.pink.shade300,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          percentBadge,
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _obterDataVencimento(Gestante g) {
    if (g.diaVencimento == null) return 'A definir';
    final dia = g.diaVencimento!.toString().padLeft(2, '0');
    return dia;
  }

  Widget _buildAvatar(Gestante g) {
    final imageProvider = (g.fotoPath != null && g.fotoPath!.isNotEmpty)
        ? _imageProviderService.buildImageProvider(g.fotoPath!)
        : null;

    final isQuitada = g.valorContrato > 0 && g.saldoDevedor <= 0;
    final bgColor = isQuitada ? const Color(0xFFE0F2F1) : const Color(0xFFFDECEF);
    final iconColor = isQuitada ? const Color(0xFF007D87) : Colors.pink.shade400;

    return CircleAvatar(
      radius: 25,
      backgroundColor: bgColor,
      child: ClipOval(
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.pregnant_woman, size: 28, color: iconColor);
                },
              )
            : Icon(Icons.pregnant_woman, size: 28, color: iconColor),
      ),
    );
  }

  Widget _buildStatusChip(Gestante g) {
    String label;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (g.valorContrato == 0) {
      label = 'A Definir';
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.add_circle_outline;
    } else if (g.contratoEntregue) {
      label = 'Contrato Entregue';
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline;
    } else {
      label = 'Pendente';
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFFB8C00);
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    
    final controlPoint1 = Offset(size.width * 0.35, size.height + 15);
    final controlPoint2 = Offset(size.width * 0.70, size.height - 50);
    final endPoint = Offset(size.width, size.height - 25);
    
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}