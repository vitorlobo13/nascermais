import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/gestante.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _maternidadeController = TextEditingController();
  DateTime? _dum;
  DateTime? _dataUltra;
  int _semanasUltra = 0;
  int _diasUltra = 0;
  DateTime? _dppFinal;
  String _classificacaoRisco = 'Risco Habitual';
  String? _fotoPath;

  // Função para selecionar a foto
  Future<void> _escolherFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _fotoPath = image.path);
    }
  }

  void _calcularDPP() {
    setState(() {
      if (_dataUltra != null) {
        int totalDiasUltra = (_semanasUltra * 7) + _diasUltra;
        int diasAte40Semanas = 280 - totalDiasUltra;
        _dppFinal = _dataUltra!.add(Duration(days: diasAte40Semanas));
      } else if (_dum != null) {
        _dppFinal = _dum!.add(const Duration(days: 280));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Gestante'),
        backgroundColor: Colors.pink.shade100,
      ),
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
                        ? (kIsWeb ? NetworkImage(_fotoPath!) : FileImage(File(_fotoPath!)) as ImageProvider)
                        : null,
                      child: _fotoPath == null 
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.pink) 
                        : null,
                    ),
                    const SizedBox(height: 8),
                    const Text('Adicionar Foto', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Gestante', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _maternidadeController,
              decoration: const InputDecoration(labelText: 'Maternidade / Hospital', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            const Text('Cálculo da DPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            // DUM
            ListTile(
              tileColor: Colors.grey.shade100,
              title: Text(_dum == null ? 'Data da Última Menstruação (DUM)' : 'DUM: ${DateFormat('dd/MM/yyyy').format(_dum!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 300)), lastDate: DateTime.now());
                if (picked != null) {
                  setState(() {
                    _dum = picked;
                    _dataUltra = null;
                    _calcularDPP();
                  });
                }
              },
            ),
            const Center(child: Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            
            // ULTRASSONOGRAFIA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  ListTile(
                    title: Text(_dataUltra == null ? 'Data da Ultrassonografia' : 'Data da Ultra: ${DateFormat('dd/MM/yyyy').format(_dataUltra!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 300)), lastDate: DateTime.now());
                      if (picked != null) {
                        setState(() {
                          _dataUltra = picked;
                          _dum = null;
                          _calcularDPP();
                        });
                      }
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Semanas'),
                          onChanged: (val) {
                            _semanasUltra = int.tryParse(val) ?? 0;
                            _calcularDPP();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Dias'),
                          onChanged: (val) {
                            _diasUltra = int.tryParse(val) ?? 0;
                            _calcularDPP();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_dppFinal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.pink.shade100,
                child: Text('DPP FINAL: ${DateFormat('dd/MM/yyyy').format(_dppFinal!)}', 
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _classificacaoRisco,
              decoration: const InputDecoration(labelText: 'Classificação de Risco', border: OutlineInputBorder()),
              items: ['Risco Habitual', 'Alto Risco'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _classificacaoRisco = val!),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
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
                    Navigator.pop(context, novaGestante);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome e calcule a DPP')));
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
}
