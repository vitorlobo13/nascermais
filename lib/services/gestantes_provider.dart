import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import '../models/gestante.dart';
import 'database_helper.dart';

class GestantesProvider extends ChangeNotifier {
  // TOGGLE: Altere para 'true' quando estiver pronto para conectar ao Firebase em produção.
  // Mantendo 'false', o aplicativo usa o SQLite local normalmente e pula a tela de login.
  static const bool usarFirebase = true;

  List<Gestante> _gestantes = [];
  bool _isLoading = false;
  bool _estaMigrando = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Gestante> get gestantes => _gestantes;
  bool get isLoading => _isLoading;

  // --- MÉTODOS DE AUTENTICAÇÃO ---
  
  User? get usuario => usarFirebase ? FirebaseAuth.instance.currentUser : null;
  bool get estaLogado => usarFirebase ? usuario != null : true;

  // Escuta as mudanças de autenticação (usado no boot do app)
  Stream<User?> get authStateChanges {
    if (usarFirebase) {
      return FirebaseAuth.instance.authStateChanges();
    } else {
      return Stream.value(null);
    }
  }

  Future<void> fazerLogin(String email, String password) async {
    if (!usarFirebase) return;
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    await carregarGestantes();
  }

  Future<void> cadastrarUsuario(String email, String password) async {
    if (!usarFirebase) return;
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    await carregarGestantes();
  }

  Future<void> fazerLogout() async {
    if (usarFirebase) {
      await FirebaseAuth.instance.signOut();
    }
    _gestantes = [];
    notifyListeners();
  }

  Future<void> recuperarSenha(String email) async {
    if (!usarFirebase) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // --- MÉTODOS DE PERSISTÊNCIA (FIRESTORE OU SQLITE) ---

  CollectionReference<Map<String, dynamic>> get _colecaoFirestore {
    if (usuario == null) {
      throw Exception('Nenhum usuário logado.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(usuario!.uid)
        .collection('gestantes');
  }

  Future<void> carregarGestantes() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (usarFirebase) {
        // 1. Antes de carregar, migra qualquer dado local existente do SQLite para o Firestore
        await _migrarDadosLocaisParaFirestore();
        
        // 2. Carrega a lista do Firestore
        final snapshot = await _colecaoFirestore.get();
        _gestantes = snapshot.docs.map((doc) => _mapearFirestoreParaModel(doc.id, doc.data())).toList();
      } else {
        // Carrega do SQLite normalizado
        _gestantes = await _dbHelper.getGestantes();
      }
    } catch (e) {
      debugPrint("Erro ao carregar gestantes: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarGestante(Gestante gestante) async {
    try {
      if (usarFirebase) {
        final docRef = _colecaoFirestore.doc();
        gestante.id = docRef.id;

        if (gestante.fotoPath != null && gestante.fotoPath!.isNotEmpty) {
          final url = await _uploadFoto(gestante.fotoPath!, gestante.id!);
          gestante.fotoPath = url;
        }

        await docRef.set(_mapearModelParaFirestore(gestante));
      } else {
        // SQLite: Insere e atualiza a referência local do ID (como texto)
        final localId = await _dbHelper.insertGestante(gestante);
        gestante.id = localId.toString();
      }
      
      _gestantes.add(gestante);
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao adicionar gestante: $e");
    }
  }

  Future<void> atualizarGestante(Gestante gestante) async {
    if (gestante.id == null) return;
    try {
      if (usarFirebase) {
        if (gestante.fotoPath != null && 
            gestante.fotoPath!.isNotEmpty && 
            !gestante.fotoPath!.startsWith('http')) {
          final url = await _uploadFoto(gestante.fotoPath!, gestante.id!);
          gestante.fotoPath = url;
        }
        await _colecaoFirestore.doc(gestante.id).set(_mapearModelParaFirestore(gestante));
      } else {
        // SQLite
        await _dbHelper.updateGestante(gestante);
      }

      // Atualiza localmente
      final index = _gestantes.indexWhere((g) => g.id == gestante.id);
      if (index != -1) {
        _gestantes[index] = gestante;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao atualizar gestante: $e");
    }
  }

  Future<void> excluirGestante(Gestante gestante) async {
    if (gestante.id == null) return;
    try {
      if (usarFirebase) {
        await _colecaoFirestore.doc(gestante.id).delete();
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('users')
              .child(usuario!.uid)
              .child('gestantes')
              .child('${gestante.id}.jpg');
          await ref.delete();
        } catch (_) {}
      } else {
        // SQLite
        final localId = int.tryParse(gestante.id!) ?? 0;
        await _dbHelper.deleteGestante(localId);
      }

      _gestantes.removeWhere((g) => g.id == gestante.id);
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao deletar gestante: $e");
    }
  }

  // --- MÉTODOS AUXILIARES, CONVERSORES E MIGRAÇÃO ---

  /// Migra de forma transparente os registros locais do SQLite para o Firestore na primeira autenticação.
  Future<void> _migrarDadosLocaisParaFirestore() async {
    if (_estaMigrando) return;
    _estaMigrando = true;
    try {
      final localGestantes = await _dbHelper.getGestantes();
      if (localGestantes.isEmpty) return;

      debugPrint("Migração: Encontradas ${localGestantes.length} gestantes no SQLite. Iniciando envio para o Firestore...");

      for (var gestante in localGestantes) {
        final oldLocalId = gestante.id;

        // 1. Gera ID no Firestore
        final docRef = _colecaoFirestore.doc();
        gestante.id = docRef.id;

        // 2. Se houver imagem local, faz o upload para o Storage
        if (gestante.fotoPath != null && gestante.fotoPath!.isNotEmpty) {
          final url = await _uploadFoto(gestante.fotoPath!, gestante.id!);
          gestante.fotoPath = url;
        }

        // 3. Salva no Firestore
        await docRef.set(_mapearModelParaFirestore(gestante));

        // 4. Deleta do SQLite para evitar duplicidades em sincronizações futuras
        if (oldLocalId != null) {
          final intId = int.tryParse(oldLocalId) ?? 0;
          await _dbHelper.deleteGestante(intId);
        }
      }
      debugPrint("Migração concluída com sucesso! Todos os registros locais foram enviados para o Firestore.");
    } catch (e) {
      debugPrint("Erro durante a migração automática de dados SQLite -> Firestore: $e");
    } finally {
      _estaMigrando = false;
    }
  }

  Future<String?> _uploadFoto(String path, String gestanteId) async {
    if (path.startsWith('http') || !usarFirebase) {
      return path; 
    }
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(usuario!.uid)
          .child('gestantes')
          .child('$gestanteId.jpg');

      if (path.startsWith('base64:')) {
        final bytes = base64Decode(path.substring(7));
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(path);
        if (!await file.exists()) return path;
        await ref.putFile(file);
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erro ao fazer upload da foto: $e");
      return path; 
    }
  }

  Gestante _mapearFirestoreParaModel(String id, Map<String, dynamic> data) {
    return Gestante(
      id: id,
      nome: data['nome'] as String,
      dppFinal: DateTime.parse(data['dppFinal'] as String),
      maternidade: data['maternidade'] as String? ?? '',
      classificacaoRisco: data['classificacaoRisco'] as String? ?? 'Risco Habitual',
      fotoPath: data['fotoPath'] as String?,
      valorContrato: (data['valorContrato'] as num?)?.toDouble() ?? 0.0,
      diaVencimento: data['diaVencimento'] as int?,
      contratoEntregue: data['contratoEntregue'] == true,
      ficha: (data['ficha'] as List? ?? []).map((f) => CartaoFicha.fromJson(f as Map<String, dynamic>)).toList(),
      pagamentos: (data['pagamentos'] as List? ?? []).map((p) => Pagamento.fromJson(p as Map<String, dynamic>)).toList(),
      arquivada: data['arquivada'] == true,
      jaNasceu: data['jaNasceu'] == true,
    );
  }

  Map<String, dynamic> _mapearModelParaFirestore(Gestante g) {
    return {
      'nome': g.nome,
      'dppFinal': g.dppFinal.toIso8601String(),
      'maternidade': g.maternidade,
      'classificacaoRisco': g.classificacaoRisco,
      'fotoPath': g.fotoPath,
      'valorContrato': g.valorContrato,
      'diaVencimento': g.diaVencimento,
      'contratoEntregue': g.contratoEntregue,
      'arquivada': g.arquivada,
      'jaNasceu': g.jaNasceu,
      'ficha': g.ficha.map((f) => f.toJson()).toList(),
      'pagamentos': g.pagamentos.map((p) => p.toJson()).toList(),
    };
  }
}

class GestantesStateScope extends InheritedNotifier<GestantesProvider> {
  const GestantesStateScope({
    super.key,
    required GestantesProvider super.notifier,
    required super.child,
  });

  static GestantesProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<GestantesStateScope>();
      assert(scope != null, 'Nenhum GestantesStateScope encontrado no contexto');
      return scope!.notifier!;
    } else {
      final scope = context.getElementForInheritedWidgetOfExactType<GestantesStateScope>()?.widget as GestantesStateScope?;
      assert(scope != null, 'Nenhum GestantesStateScope encontrado no contexto');
      return scope!.notifier!;
    }
  }
}
