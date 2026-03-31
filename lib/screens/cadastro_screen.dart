import '../models/gestante.dart';
import '../services/database_helper.dart';
import '../services/image_escolher.dart';
import '../services/image_convert_database.dart';
import '../services/calculo_dum.dart';
import '../services/calculo_ultra.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _maternidadeController = TextEditingController();
  final _imageEscolher = ImageEscolher();
  final _imageProviderService = ImageProviderService();
  DateTime? _dum;
  DateTime? _dataUltra;
  int _semanasUltra = 0;
  int _diasUltra = 0;
  DateTime? _dppDireta; 	
  DateTime? _dppFinal;
  String _classificacaoRisco = 'Risco Habitual';
  String? _fotoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //TEXTO E CABEÇALHO TOPO DA TELA
      appBar: AppBar(
        title: const Text('Cadastrar Gestante'),
        backgroundColor: Colors.pink.shade100,
      ),

      //CORPO DA TELA DE CADASTRO
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // SELETOR DE FOTO (Única adição nova)
            Center(
              child: GestureDetector(
                onTap: _escolherFoto,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.pink.shade50,
                      backgroundImage: _fotoPath != null 
                          ? _buildImageProvider(_fotoPath!)
                          : null,
                      child: _fotoPath == null 
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.pink) 
                        : null,
                    ),
                    // TEXTO DE BAIXO DO CÍRCULO DA FOTO
                    const SizedBox(height: 8),
                    const Text('Adicionar Foto', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),

            //TEXTO E NOME DA GESTANTE
            const SizedBox(height: 24),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Gestante', border: OutlineInputBorder()),
            ),

            //TEXTO E NOME DA MATERNIDADE
            const SizedBox(height: 16),            
            TextField(
              controller: _maternidadeController,
              decoration: const InputDecoration(labelText: 'Maternidade / Hospital', border: OutlineInputBorder()),
            ),

            //TEXTO E CABEÇALHO DO CADASTRO DO CÁLCULO
            const SizedBox(height: 24),
            const Text('Cálculo da DPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            
            // CADASTRO DA ÚLTIMA MENSTRUAÇÃO
            const SizedBox(height: 8),
            CampoDataDUM(
              dataSelecionada: _dum,
              corFundo: Colors.grey.shade100,
              labelPadrao: 'Data da Última Menstruação (DUM)',
              prefixoTexto: 'DUM: ',
              onDataSelecionada: (novaData) {
                setState(() {
                  _dum = novaData;
                  _dataUltra = null;
                  _calcularDPP();
                });
              },
            ),

            //TEXTO DO OU
            const Center(child: Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            
            //CADASTRO DA DPP DIRETA
            ListTile(
              tileColor: Colors.grey.shade100,
              title: Text(_dppDireta == null ? 'Data Provável do Parto (DPP) Direta' : 'DPP Direta: ${DateFormat('dd/MM/yyyy').format(_dppDireta!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 300)), lastDate: DateTime.now().add(const Duration(days: 280)));
                if (picked != null) {
                  setState(() {
                    _dppDireta = picked;
                    _dum = null;
                    _dataUltra = null;
                    _semanasUltra = 0;
                    _diasUltra = 0;
                    _calcularDPP();
                  });
                }
              },
            ),

            //TEXTO DO OU
            const Center(child: Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),            
            
            //CADASTRO DA ULTRASSONOGRAFIA
            CampoCadastroUltra(
              dataUltra: _dataUltra,
              corFundo: Colors.blue.shade50, 
              labelData: 'Data da Ultrassonografia',
              onDataSelecionada: (novaData) {
                setState(() {
                  _dataUltra = novaData;
                  _dum = null; // Limpa DUM ao selecionar Ultra
                  _calcularDPP();
                });
              },
              onSemanasChanged: (val) {
                setState(() {
                  _semanasUltra = int.tryParse(val) ?? 0;
                  _calcularDPP();
                });
              },
              onDiasChanged: (val) {
                setState(() {
                  _diasUltra = int.tryParse(val) ?? 0;
                  _calcularDPP();
                });
              },
            ),
            
            //DPP FINAL CALCULADA
            const SizedBox(height: 16),
            if (_dppFinal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.pink.shade100,
                child: Text('DPP FINAL: ${DateFormat('dd/MM/yyyy').format(_dppFinal!)}', 
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            
            //CLASSIFICAÇAO DE RISCO
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _classificacaoRisco,
              decoration: const InputDecoration(labelText: 'Classificação de Risco', border: OutlineInputBorder()),
              items: ['Risco Habitual', 'Alto Risco'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _classificacaoRisco = val!),
            ),

            //BOTÃO PARA SALVAR O CADASTRO
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  //SE PREENCHEU O NOME E A DPP
                  if (_nomeController.text.isNotEmpty && _dppFinal != null) {
                      final novaGestante = Gestante(
                        nome: _nomeController.text,
                        dppFinal: _dppFinal!,
                        maternidade: _maternidadeController.text,
                        classificacaoRisco: _classificacaoRisco,
                        fotoPath: _fotoPath,
                        ficha: [
                          CartaoFicha(titulo: 'Dpp ${DateFormat('dd/MM/yyyy').format(_dppFinal!)}', concluido: true),
                          CartaoFicha(titulo: 'Maternidade: ${_maternidadeController.text}', concluido: true),
                          CartaoFicha(titulo: 'Risco: $_classificacaoRisco', concluido: true),
                        ],
                    );
                    // INSERE NO BANCO E PEGA O ID GERADO
                    int idGerado = await DatabaseHelper().insertGestante(novaGestante);
                    novaGestante.id = idGerado;
                    if (!mounted) return;
           
                    Navigator.pop(context, novaGestante);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome da gestante e calcule a DPP')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text('Salvar Cadastro', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //FUNÇÕES USADAS NO CADASTRO

  // Função para selecionar a foto
  Future<void> _escolherFoto() async {
    final fotoPath = await _imageEscolher.escolherFoto(context);
    if (fotoPath != null) {
      setState(() {
        _fotoPath = fotoPath;
      });
    }
  }

  //CALCULAR DPP
  void _calcularDPP() {
    setState(() {
	  if (_dppDireta != null) {
        _dppFinal = _dppDireta;
      } else if (_dataUltra != null) {
        int totalDiasUltra = (_semanasUltra * 7) + _diasUltra;
        int diasAte40Semanas = 280 - totalDiasUltra;
        _dppFinal = _dataUltra!.add(Duration(days: diasAte40Semanas));
      } else if (_dum != null) {
        _dppFinal = _dum!.add(const Duration(days: 280));
	  } else {
        _dppFinal = null;							 
      }
    });
  }

  //Converter imagem para o database
  ImageProvider? _buildImageProvider(String path) {
    return _imageProviderService.buildImageProvider(path);
  }

}

