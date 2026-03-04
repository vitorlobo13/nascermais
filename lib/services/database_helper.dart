import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Para FFI
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Para Web
import '../models/gestante.dart';



class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    DatabaseFactory dbFactory;
    String path;

    if (kIsWeb) {
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
        version: 1,
        onCreate: _onCreate,
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
        ficha TEXT, 
        valorContrato REAL,
        pagamentos TEXT, 
        contratoEntregue INTEGER,
        arquivada INTEGER DEFAULT 0 -- NOVA COLUNA: 0 = Ativa, 1 = Arquivada
      )
    ''');
  }

  // Operações CRUD
  Future<int> insertGestante(Gestante gestante) async {
    Database db = await database;
    return await db.insert('gestantes', gestante.toMap());
  }

  Future<List<Gestante>> getGestantes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('gestantes');
    return List.generate(maps.length, (i) => Gestante.fromMap(maps[i]));
  }

  Future<int> updateGestante(Gestante gestante) async {
    Database db = await database;
    return await db.update(
      'gestantes',
      gestante.toMap(),
      where: 'id = ?',
      whereArgs: [gestante.id],
    );
  }

  Future<int> deleteGestante(int id) async {
    Database db = await database;
    return await db.delete('gestantes', where: 'id = ?', whereArgs: [id]);
  }
}
