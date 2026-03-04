import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/gestante.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:typed_data';
import 'dart:convert';



class EditarGestanteScreen extends StatefulWidget {
  final Gestante gestante;

  const EditarGestanteScreen({super.key, required this.gestante});

  @override
  State<EditarGestanteScreen> createState() => _EditarGestanteScreenState();
}

class _EditarGestanteScreenState extends State<EditarGestanteScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _maternidadeController;
  DateTime? _dum;
  DateTime? _dataUltra;
  int _semanasUltra = 0;
  int _diasUltra = 0;
  DateTime? _dppDireta; // Nova variável para DPP direta
  DateTime? _dppFinal;
  late String _classificacaoRisco;
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.gestante.nome);
    _maternidadeController = TextEditingController(text: widget.gestante.maternidade);
    _dppFinal = widget.gestante.dppFinal;
    _classificacaoRisco = widget.gestante.classificacaoRisco;
    _fotoPath = widget.gestante.fotoPath;

    // Se a DPP final já existe, podemos inferir a DUM ou a data da ultra para exibição
    // No entanto, para edição, é mais seguro deixar o usuário redefinir se necessário
    // ou simplesmente exibir a DPP final calculada.
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _maternidadeController.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final ImagePicker picker = ImagePicker();
    
    // 1. Seleciona a imagem da galeria
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // 2. Abre o editor de corte (Crop)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Mantém o quadrado perfeito
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            toolbarColor: Colors.pink,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // Trava a proporção em 1:1
          ),
          IOSUiSettings(
            title: 'Ajustar Foto',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

        if (croppedFile != null) {
              if (kIsWeb) {
                // CONVERSÃO PARA BASE64 NO WEB
                final bytes = await croppedFile.readAsBytes(); //
                final base64Image = base64Encode(bytes); //
                setState(() => _fotoPath = 'base64:$base64Image');
              } else {
                setState(() => _fotoPath = croppedFile.path);
              }
            }
          }
        }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Gestante'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    const SizedBox(height: 8),
                    const Text('Alterar Foto', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
            // DPP DIRETA
            ListTile(
              tileColor: Colors.grey.shade100,
              title: Text(_dppDireta == null ? 'Data Provável do Parto (DPP) Direta' : 'DPP Direta: ${DateFormat('dd/MM/yyyy').format(_dppDireta!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 300)), lastDate: DateTime.now().add(const Duration(days: 280))); // DPP pode ser no futuro
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
            
            const Center(child: Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            
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
              initialValue: _classificacaoRisco,
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
                    final gestanteAtualizada = Gestante(
                      nome: _nomeController.text,
                      dppFinal: _dppFinal!,
                      maternidade: _maternidadeController.text,
                      classificacaoRisco: _classificacaoRisco,
                      fotoPath: _fotoPath,
                      ficha: widget.gestante.ficha, // Manter a ficha existente
                      valorContrato: widget.gestante.valorContrato, // Manter valor do contrato
                      pagamentos: widget.gestante.pagamentos, // Manter pagamentos
                      contratoEntregue: widget.gestante.contratoEntregue, // Manter status do contrato
                    );
                    Navigator.pop(context, gestanteAtualizada);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome e calcule a DPP')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _buildImageProvider(String path) {
  if (path.startsWith('data:image')) {
    // Data URI — extrair o base64 após a vírgula
    final base64Str = path.split(',').last;
    return MemoryImage(base64Decode(base64Str));
  } else if (path.startsWith('base64:')) {
    return MemoryImage(base64Decode(path.substring(7)));
  } else if (path.startsWith('http')) {
    return NetworkImage(path);
  } else {
    // Caminho local (só funciona em mobile)
    return FileImage(File(path));
  }
  }

}
