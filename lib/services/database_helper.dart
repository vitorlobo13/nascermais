import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Para FFI
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Para Web
import '../models/gestante.dart';



class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static String? overridePath;
  static DatabaseFactory? overrideFactory;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static void reset() {
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    DatabaseFactory dbFactory;
    String path;

    if (overrideFactory != null) {
      dbFactory = overrideFactory!;
      path = overridePath ?? 'test.db';
    } else if (kIsWeb) {
      // Configuração específica para WEB
      dbFactory = databaseFactoryFfiWeb;
      path = 'nascermais_web.db'; // Na web, o caminho é apenas um identificador
    } else {
      // Configuração para Android/iOS
      dbFactory = databaseFactory; // Usa a factory padrão do sqflite
      path = join(await getDatabasesPath(), 'nascermais.db');
    }

    return await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gestantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        dppFinal TEXT NOT NULL,
        maternidade TEXT,
        classificacaoRisco TEXT,
        fotoPath TEXT,
        valorContrato REAL,
        diaVencimento INTEGER,
        contratoEntregue INTEGER,
        arquivada INTEGER DEFAULT 0,
        jaNasceu INTEGER DEFAULT 0,
        dataNascimento TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cartoes_ficha (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gestanteId INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        concluido INTEGER DEFAULT 0,
        FOREIGN KEY (gestanteId) REFERENCES gestantes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE subtopicos_ficha (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cartaoId INTEGER NOT NULL,
        texto TEXT NOT NULL,
        concluido INTEGER DEFAULT 0,
        FOREIGN KEY (cartaoId) REFERENCES cartoes_ficha (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pagamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gestanteId INTEGER NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        descricao TEXT,
        FOREIGN KEY (gestanteId) REFERENCES gestantes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE gestantes ADD COLUMN diaVencimento INTEGER DEFAULT 5'
        );
      } catch (_) {}
      print("Database upgraded to version 3: Column 'diaVencimento' added.");
    }

    if (oldVersion < 4) {
      // 1. Rename existing table
      await db.execute('ALTER TABLE gestantes RENAME TO gestantes_old');

      // 2. Create new normalized tables
      await db.execute('''
        CREATE TABLE gestantes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          dppFinal TEXT NOT NULL,
          maternidade TEXT,
          classificacaoRisco TEXT,
          fotoPath TEXT,
          valorContrato REAL,
          diaVencimento INTEGER,
          contratoEntregue INTEGER,
          arquivada INTEGER DEFAULT 0,
          jaNasceu INTEGER DEFAULT 0,
          dataNascimento TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE cartoes_ficha (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gestanteId INTEGER NOT NULL,
          titulo TEXT NOT NULL,
          concluido INTEGER DEFAULT 0,
          FOREIGN KEY (gestanteId) REFERENCES gestantes (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE subtopicos_ficha (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cartaoId INTEGER NOT NULL,
          texto TEXT NOT NULL,
          concluido INTEGER DEFAULT 0,
          FOREIGN KEY (cartaoId) REFERENCES cartoes_ficha (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE pagamentos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gestanteId INTEGER NOT NULL,
          valor REAL NOT NULL,
          data TEXT NOT NULL,
          descricao TEXT,
          FOREIGN KEY (gestanteId) REFERENCES gestantes (id) ON DELETE CASCADE
        )
      ''');

      // 3. Migrate data
      final List<Map<String, dynamic>> oldGestantes = await db.query('gestantes_old');
      for (var old in oldGestantes) {
        final gestanteId = await db.insert('gestantes', {
          'id': old['id'],
          'nome': old['nome'],
          'dppFinal': old['dppFinal'],
          'maternidade': old['maternidade'],
          'classificacaoRisco': old['classificacaoRisco'],
          'fotoPath': old['fotoPath'],
          'valorContrato': old['valorContrato'],
          'diaVencimento': old['diaVencimento'],
          'contratoEntregue': old['contratoEntregue'],
          'arquivada': old['arquivada'] ?? 0,
          'jaNasceu': old['jaNasceu'] ?? 0,
          'dataNascimento': old['dataNascimento'],
        });

        // Migrate cards
        if (old['ficha'] != null) {
          try {
            final List fichaJson = jsonDecode(old['ficha'] as String);
            for (var cardMap in fichaJson) {
              final cardId = await db.insert('cartoes_ficha', {
                'gestanteId': gestanteId,
                'titulo': cardMap['titulo'],
                'concluido': (cardMap['concluido'] == true) ? 1 : 0,
              });

              final List subtopicosJson = cardMap['subtopicos'] ?? [];
              for (var subMap in subtopicosJson) {
                await db.insert('subtopicos_ficha', {
                  'cartaoId': cardId,
                  'texto': subMap['texto'],
                  'concluido': (subMap['concluido'] == true) ? 1 : 0,
                });
              }
            }
          } catch (e) {
            print("Error migrating ficha for gestante $gestanteId: $e");
          }
        }

        // Migrate payments
        if (old['pagamentos'] != null) {
          try {
            final List pagamentosJson = jsonDecode(old['pagamentos'] as String);
            for (var pMap in pagamentosJson) {
              await db.insert('pagamentos', {
                'gestanteId': gestanteId,
                'valor': pMap['valor'],
                'data': pMap['data'],
                'descricao': pMap['descricao'],
              });
            }
          } catch (e) {
            print("Error migrating pagamentos for gestante $gestanteId: $e");
          }
        }
      }

      // 4. Drop old table
      await db.execute('DROP TABLE gestantes_old');
      print("Database upgraded to version 4: Normalized schema.");
    }

    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE gestantes ADD COLUMN dataNascimento TEXT'
        );
      } catch (_) {}
      print("Database upgraded to version 5: Column 'dataNascimento' added.");
    }
  }

  // Operações CRUD normalizadas
  Future<int> insertGestante(Gestante gestante) async {
    Database db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert('gestantes', {
        'nome': gestante.nome,
        'dppFinal': gestante.dppFinal.toIso8601String(),
        'maternidade': gestante.maternidade,
        'classificacaoRisco': gestante.classificacaoRisco,
        'fotoPath': gestante.fotoPath,
        'valorContrato': gestante.valorContrato,
        'diaVencimento': gestante.diaVencimento,
        'contratoEntregue': gestante.contratoEntregue ? 1 : 0,
        'arquivada': gestante.arquivada ? 1 : 0,
        'jaNasceu': gestante.jaNasceu ? 1 : 0,
        'dataNascimento': gestante.dataNascimento?.toIso8601String(),
      });

      // Salva cartões
      for (var card in gestante.ficha) {
        final cardId = await txn.insert('cartoes_ficha', {
          'gestanteId': id,
          'titulo': card.titulo,
          'concluido': card.concluido ? 1 : 0,
        });

        // Salva subtópicos
        for (var sub in card.subtopicos) {
          await txn.insert('subtopicos_ficha', {
            'cartaoId': cardId,
            'texto': sub.texto,
            'concluido': sub.concluido ? 1 : 0,
          });
        }
      }

      // Salva pagamentos
      for (var p in gestante.pagamentos) {
        await txn.insert('pagamentos', {
          'gestanteId': id,
          'valor': p.valor,
          'data': p.data.toIso8601String(),
          'descricao': p.descricao,
        });
      }

      return id;
    });
  }

  Future<List<Gestante>> getGestantes() async {
    Database db = await database;
    final List<Map<String, dynamic>> gestanteMaps = await db.query('gestantes');
    
    List<Gestante> result = [];
    for (var gMap in gestanteMaps) {
      final gestanteId = gMap['id'] as int;
      
      // 1. Busca cartões
      final List<Map<String, dynamic>> cardMaps = await db.query(
        'cartoes_ficha',
        where: 'gestanteId = ?',
        whereArgs: [gestanteId],
      );
      
      List<CartaoFicha> cards = [];
      for (var cMap in cardMaps) {
        final cardId = cMap['id'] as int;
        
        // Busca subtópicos
        final List<Map<String, dynamic>> subMaps = await db.query(
          'subtopicos_ficha',
          where: 'cartaoId = ?',
          whereArgs: [cardId],
        );
        
        List<Subtopico> subtopics = subMaps.map((sMap) => Subtopico(
          texto: sMap['texto'] as String,
          concluido: sMap['concluido'] == 1,
        )).toList();
        
        cards.add(CartaoFicha(
          titulo: cMap['titulo'] as String,
          concluido: cMap['concluido'] == 1,
          subtopicos: subtopics,
        ));
      }
      
      // 2. Busca pagamentos
      final List<Map<String, dynamic>> pMaps = await db.query(
        'pagamentos',
        where: 'gestanteId = ?',
        whereArgs: [gestanteId],
      );
      
      List<Pagamento> payments = pMaps.map((pMap) => Pagamento(
        valor: (pMap['valor'] as num).toDouble(),
        data: DateTime.parse(pMap['data'] as String),
        descricao: pMap['descricao'] as String? ?? '',
      )).toList();
      
      // 3. Monta o objeto Gestante
      result.add(Gestante(
        id: gestanteId.toString(),
        nome: gMap['nome'] as String,
        dppFinal: DateTime.parse(gMap['dppFinal'] as String),
        maternidade: gMap['maternidade'] as String? ?? '',
        classificacaoRisco: gMap['classificacaoRisco'] as String? ?? 'Risco Habitual',
        fotoPath: gMap['fotoPath'] as String?,
        valorContrato: (gMap['valorContrato'] as num?)?.toDouble() ?? 0.0,
        diaVencimento: gMap['diaVencimento'] as int?,
        contratoEntregue: gMap['contratoEntregue'] == 1,
        ficha: cards,
        pagamentos: payments,
        arquivada: gMap['arquivada'] == 1,
        jaNasceu: gMap['jaNasceu'] == 1,
        dataNascimento: gMap['dataNascimento'] != null ? DateTime.parse(gMap['dataNascimento'] as String) : null,
      ));
    }
    
    return result;
  }

  Future<int> updateGestante(Gestante gestante) async {
    if (gestante.id == null) return 0;
    Database db = await database;
    return await db.transaction((txn) async {
      // 1. Atualiza dados básicos
      final rows = await txn.update(
        'gestantes',
        {
          'nome': gestante.nome,
          'dppFinal': gestante.dppFinal.toIso8601String(),
          'maternidade': gestante.maternidade,
          'classificacaoRisco': gestante.classificacaoRisco,
          'fotoPath': gestante.fotoPath,
          'valorContrato': gestante.valorContrato,
          'diaVencimento': gestante.diaVencimento,
          'contratoEntregue': gestante.contratoEntregue ? 1 : 0,
          'arquivada': gestante.arquivada ? 1 : 0,
          'jaNasceu': gestante.jaNasceu ? 1 : 0,
          'dataNascimento': gestante.dataNascimento?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [gestante.id],
      );
      
      // 2. Remove relacionamentos antigos para recriá-los
      final List<Map<String, dynamic>> cardMaps = await txn.query(
        'cartoes_ficha',
        columns: ['id'],
        where: 'gestanteId = ?',
        whereArgs: [gestante.id],
      );
      for (var cardMap in cardMaps) {
        final cardId = cardMap['id'];
        await txn.delete('subtopicos_ficha', where: 'cartaoId = ?', whereArgs: [cardId]);
      }
      await txn.delete('cartoes_ficha', where: 'gestanteId = ?', whereArgs: [gestante.id]);
      await txn.delete('pagamentos', where: 'gestanteId = ?', whereArgs: [gestante.id]);
      
      // 3. Recria cartões
      for (var card in gestante.ficha) {
        final cardId = await txn.insert('cartoes_ficha', {
          'gestanteId': gestante.id,
          'titulo': card.titulo,
          'concluido': card.concluido ? 1 : 0,
        });
        
        // Recria subtópicos
        for (var sub in card.subtopicos) {
          await txn.insert('subtopicos_ficha', {
            'cartaoId': cardId,
            'texto': sub.texto,
            'concluido': sub.concluido ? 1 : 0,
          });
        }
      }
      
      // 4. Recria pagamentos
      for (var p in gestante.pagamentos) {
        await txn.insert('pagamentos', {
          'gestanteId': gestante.id,
          'valor': p.valor,
          'data': p.data.toIso8601String(),
          'descricao': p.descricao,
        });
      }
      
      return rows;
    });
  }

  Future<int> deleteGestante(int id) async {
    Database db = await database;
    return await db.transaction((txn) async {
      final List<Map<String, dynamic>> cardMaps = await txn.query(
        'cartoes_ficha',
        columns: ['id'],
        where: 'gestanteId = ?',
        whereArgs: [id],
      );
      for (var cardMap in cardMaps) {
        final cardId = cardMap['id'];
        await txn.delete('subtopicos_ficha', where: 'cartaoId = ?', whereArgs: [cardId]);
      }
      await txn.delete('cartoes_ficha', where: 'gestanteId = ?', whereArgs: [id]);
      await txn.delete('pagamentos', where: 'gestanteId = ?', whereArgs: [id]);
      return await txn.delete('gestantes', where: 'id = ?', whereArgs: [id]);
    });
  }
}
