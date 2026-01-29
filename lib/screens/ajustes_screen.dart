import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  // Função para abrir o e-mail de feedback
  Future<void> _enviarFeedback() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'vitorlobo10@gmail.com',
      queryParameters: {
        'subject': 'Feedback App Nascer+ - Versão Beta',
        'body': 'Olá! Gostaria de sugerir o seguinte para o aplicativo...'
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri,
                       mode: LaunchMode.externalApplication,
                       );
      } else {
        // Fallback para web ou dispositivos sem app de email configurado
        debugPrint('Não foi possível abrir o app de e-mail');
      }
    } catch (e) {
      debugPrint('Erro ao tentar abrir e-mail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes e Ajuda'),
        backgroundColor: Colors.grey.shade200,
      ),
      body: ListView(
        children: [
          // CABEÇALHO DA VERSÃO
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.pink.shade50,
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 50, color: Colors.pink),
                const SizedBox(height: 10),
                const Text(
                  'Nascer+ Beta',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text('Versão 1.0.0', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                const Text(
                  'Obrigado por participar dos testes! Seu feedback é fundamental para o crescimento deste projeto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // SEÇÃO DE SUPORTE
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('SUPORTE E FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.blue),
            title: const Text('Enviar Feedback por E-mail'),
            subtitle: const Text('vitorlobo10@gmail.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _enviarFeedback,
          ),

          const Divider(),

          // SEÇÃO DE GUIA RÁPIDO
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('GUIA RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildGuiaItem(Icons.people, 'Gestantes', 'Cadastre suas clientes e use os cartões para registrar aulas e informações do pré-natal. Dentro do cartão você pode registrar subtópicos, por exemplo, registrar medicamentos.'),
          _buildGuiaItem(Icons.attach_money, 'Financeiro', 'Defina o valor do contrato e registre cada pagamento recebido para ter controle total.'),
          _buildGuiaItem(Icons.search, 'Busca', 'Use a barra de busca no topo para encontrar rapidamente qualquer gestante pelo nome.'),
          _buildGuiaItem(Icons.delete_sweep, 'Excluir', 'Arraste uma ficha para a esquerda na lista principal para excluí-la permanentemente.'),

          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Desenvolvido com ❤️ para quem vive o nascer',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGuiaItem(IconData icon, String titulo, String descricao) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.pink.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(descricao, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


