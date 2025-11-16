import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'products.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prdNo TEXT,
        prdNom TEXT,
        prdQr TEXT,
        uploaded INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getPendingProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'uploaded = ?', whereArgs: [0]);
    return List.generate(maps.length, (i) {
      return Product.fromJson(maps[i]);
    });
  }

  Future<int> markAsUploaded(String prdNo) async {
    final db = await database;
    return await db.update('products', {'uploaded': 1}, where: 'prdNo = ?', whereArgs: [prdNo]);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product.fromJson(maps[i]);
    });
  }
}
