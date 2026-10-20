import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/gestante.dart';

class GestantesProvider extends ChangeNotifier {
  static const bool usarFirebase = true;

  List<Gestante> _gestantes = [];
  bool _isLoading = false;

  List<Gestante> get gestantes => _gestantes;
  bool get isLoading => _isLoading;

  // --- MÉTODOS DE AUTENTICAÇÃO ---
  
  User? get usuario => FirebaseAuth.instance.currentUser;
  bool get estaLogado => usuario != null;

  // Escuta as mudanças de autenticação (usado no boot do app)
  Stream<User?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges();
  }

  // PERFORMANCE: não carrega as gestantes aqui. Após o login, o authStateChanges
  // abre a MainNavigation, que já faz a carga inicial (evita baixar tudo 2 vezes).
  Future<void> fazerLogin(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> cadastrarUsuario(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> fazerLogout() async {
    await FirebaseAuth.instance.signOut();
    _gestantes = [];
    notifyListeners();
  }

  Future<void> recuperarSenha(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // --- MÉTODOS DE PERSISTÊNCIA (FIRESTORE) ---

  CollectionReference<Map<String, dynamic>> get _colecaoFirestore {
    if (usuario == null) {
      throw Exception('Nenhum usuário logado.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(usuario!.uid)
        .collection('gestantes');
  }

  // PERFORMANCE: se já existe uma carga em andamento, reaproveita a mesma
  // em vez de disparar outra leitura completa da coleção.
  Future<void>? _cargaEmAndamento;

  Future<void> carregarGestantes() {
    return _cargaEmAndamento ??=
        _executarCarga().whenComplete(() => _cargaEmAndamento = null);
  }

  Future<void> _executarCarga() async {
    // PERFORMANCE: a tela cheia de carregamento só aparece na primeira carga
    // (lista ainda vazia). Recargas posteriores acontecem em segundo plano,
    // sem esconder a lista que a usuária já está vendo.
    final primeiraCarga = _gestantes.isEmpty;
    if (primeiraCarga) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      // Carrega a lista do Firestore
      final snapshot = await _colecaoFirestore.get();
      _gestantes = snapshot.docs.map((doc) => _mapearFirestoreParaModel(doc.id, doc.data())).toList();
    } catch (e) {
      developer.log("Erro ao carregar gestantes", error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarGestante(Gestante gestante) async {
    try {
      final docRef = _colecaoFirestore.doc();
      gestante.id = docRef.id;

      // PERFORMANCE: o cadastro não espera mais o upload da foto.
      // Grava o documento primeiro (sem a foto), libera a tela e envia a foto
      // em segundo plano. Enquanto isso, a foto local continua aparecendo no app.
      final fotoAtual = gestante.fotoPath;
      final String? fotoParaEnviar = (fotoAtual != null &&
              fotoAtual.isNotEmpty &&
              !fotoAtual.startsWith('http'))
          ? fotoAtual
          : null;

      final dados = _mapearModelParaFirestore(gestante);
      if (fotoParaEnviar != null) {
        dados['fotoPath'] = null;
      }

      await docRef.set(dados);
      _gestantes.add(gestante);
      notifyListeners();

      if (fotoParaEnviar != null) {
        unawaited(_enviarFotoEmSegundoPlano(gestante, fotoParaEnviar, docRef));
      }
    } catch (e) {
      developer.log("Erro ao adicionar gestante", error: e);
    }
  }

  Future<void> _enviarFotoEmSegundoPlano(
    Gestante gestante,
    String fotoLocal,
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      final url = await _uploadFoto(fotoLocal, gestante.id!);
      if (url != null && url.startsWith('http')) {
        gestante.fotoPath = url;
        await docRef.update({'fotoPath': url});
        notifyListeners();
      }
    } catch (e) {
      developer.log("Erro ao enviar foto em segundo plano", error: e);
    }
  }

  Future<void> atualizarGestante(Gestante gestante) async {
    if (gestante.id == null) return;

    // PERFORMANCE: atualiza a lista local e as telas IMEDIATAMENTE,
    // sem esperar a resposta do servidor (que antes era compensada
    // recarregando a coleção inteira ao voltar de cada tela).
    final index = _gestantes.indexWhere((g) => g.id == gestante.id);
    if (index != -1) {
      _gestantes[index] = gestante;
    }
    notifyListeners();

    try {
      if (gestante.fotoPath != null &&
          gestante.fotoPath!.isNotEmpty &&
          !gestante.fotoPath!.startsWith('http')) {
        final url = await _uploadFoto(gestante.fotoPath!, gestante.id!);
        gestante.fotoPath = url;
      }
      await _colecaoFirestore.doc(gestante.id).set(_mapearModelParaFirestore(gestante));

      // Notifica de novo caso a foto tenha virado URL após o upload
      notifyListeners();
    } catch (e) {
      developer.log("Erro ao atualizar gestante", error: e);
    }
  }

  Future<void> excluirGestante(Gestante gestante) async {
    if (gestante.id == null) return;
    try {
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

      _gestantes.removeWhere((g) => g.id == gestante.id);
      notifyListeners();
    } catch (e) {
      developer.log("Erro ao deletar gestante", error: e);
    }
  }

  // --- MÉTODOS AUXILIARES E CONVERSORES ---

  Future<String?> _uploadFoto(String path, String gestanteId) async {
    if (path.startsWith('http')) {
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
      developer.log("Erro ao fazer upload da foto", error: e);
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
      dataNascimento: data['dataNascimento'] != null ? DateTime.parse(data['dataNascimento'] as String) : null,
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
      'dataNascimento': g.dataNascimento?.toIso8601String(),
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
