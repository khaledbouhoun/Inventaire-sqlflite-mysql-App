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
    print("------DBHelper _initDB called");
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'InvontaireDataBase.db');
    print("Database path = $path");
    return await openDatabase(path, version: 1, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        prd_no TEXT PRIMARY KEY,
        prd_nom TEXT,
        prd_qr TEXT,
        uploaded INTEGER DEFAULT 0
      )
    ''');
    // Create an index on prd_qr to speed up queries that filter by this column
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_qr ON products(prd_qr)');
    print("Products table created");
  }

  // Optional upgrade logic for future schema changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implement migration if needed
  }

  // Get a single product by its prd_no
  Future<Product?> getProduct(String prdNo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'prd_no = ?', whereArgs: [prdNo], limit: 1);
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  // Update an existing product (returns number of rows affected)
  Future<int> updateProduct(Product product) async {
    final db = await database;
    final prdNo = product.toJson()['prd_no'];
    return await db.update(
      'products',
      product.toJson(),
      where: 'prd_no = ?',
      whereArgs: [prdNo],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete a product by prd_no
  Future<int> deleteProduct(String prdNo) async {
    final db = await database;
    return await db.delete('products', where: 'prd_no = ?', whereArgs: [prdNo]);
  }

  // Count products in the table
  Future<int> countProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close the database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print('Database closed');
    }
  }

  // Insert a single product (replace if exists)
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Insert multiple products in a batch
  Future<List<Product>> insertAllProducts(List<Product> products) async {
    print("------DBHelper insertAllProducts called");
    final db = await database;
    final batch = db.batch();

    for (var product in products) {
      batch.insert('products', product.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    try {
      await batch.commit(noResult: true); // noResult true is faster
      print("✅ Inserted ${products.length} products into local database");
      return products;
    } catch (e) {
      print('Batch insert failed: $e');
      return [];
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps;
  }

  // Get products not yet uploaded
  Future<List<Product>> getPendingProducts() async {
    print("------DBHelper getPendingProducts called");
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: '''uploaded = ? AND (prd_qr IS NOT NULL AND prd_qr != '')''',
      whereArgs: [0],
    );
    print("------ Pending products count = ${maps.length}");
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  // Mark product as uploaded
  Future<int> markAsUploaded(String prdNo) async {
    print("------DBHelper markAsUploaded called for $prdNo");
    final db = await database;
    int count = await db.update('products', {'uploaded': 1}, where: 'prd_no = ?', whereArgs: [prdNo]);
    print("Rows updated = $count");
    return count;
  }

  // Optional: Clear database (useful for development)
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('products');
    print("Database cleared");
  }
}
