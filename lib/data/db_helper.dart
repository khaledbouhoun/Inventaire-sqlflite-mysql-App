import 'dart:io';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/data/model/gestqr.dart'; // Ensure this import exists
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

    // 1. Get the safe internal path (Works on Android & iOS)
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'zakawatt_inventaire.db');
    // copyDatabaseToDownloads();

    print("Database path = $path");

    // 2. Open the database
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure, // Essential for Foreign Keys
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Enable Foreign Keys every time DB is opened
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create Products Table
    await db.execute('''
      CREATE TABLE products(
        prd_no TEXT PRIMARY KEY,
        prd_nom TEXT,
        prd_qr TEXT,
        uploaded INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_qr ON products(prd_qr)');
    print("Products table created");

    // 2. Create GestQR Table
    await db.execute('''
      CREATE TABLE gestqr (
        gqr_no INTEGER,
        gqr_lemp_no INTEGER,
        gqr_usr_no INTEGER,
        gqr_prd_no TEXT,
        gqr_date TEXT,
        is_uploaded INTEGER DEFAULT 0,
        PRIMARY KEY (gqr_lemp_no, gqr_usr_no, gqr_no),
        FOREIGN KEY (gqr_prd_no) REFERENCES products(prd_no) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');
    print("GestQR table created (cascade enabled)");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gestqr (
          gqr_no INTEGER,
          gqr_lemp_no INTEGER,
          gqr_usr_no INTEGER,
          gqr_prd_no TEXT,
          gqr_date TEXT,
          is_uploaded INTEGER DEFAULT 0,
          PRIMARY KEY (gqr_lemp_no, gqr_usr_no, gqr_no),
          FOREIGN KEY (gqr_prd_no) REFERENCES products(prd_no) ON DELETE CASCADE ON UPDATE CASCADE
        )
      ''');
      print("Upgraded DB to version 2: Created gestqr table");
    }
  }

  // ========================= GEST QR METHODS =========================

  Future<List<GestQr>> insertAllGestqr(List<GestQr> gestQrs) async {
    final db = await database;
    final batch = db.batch();

    // --- 1. Incoming composite keys ---
    final incomingKeys = gestQrs.map((g) => [g.gqrLempNo, g.gqrUsrNo, g.gqrNo]).toList();

    // --- 2. Local existing keys ---
    final result = await db.query('gestqr', columns: ['gqr_lemp_no', 'gqr_usr_no', 'gqr_no']);
    final localKeys = result.map((e) => [e['gqr_lemp_no'] as int, e['gqr_usr_no'] as int, e['gqr_no'] as int]).toList();

    // --- 3. Keys to delete ---
    final toDelete = localKeys
        .where(
          (localKey) => !incomingKeys.any((incKey) => incKey[0] == localKey[0] && incKey[1] == localKey[1] && incKey[2] == localKey[2]),
        )
        .toList();

    // --- 4. Upsert incoming gestQrs ---
    for (var g in gestQrs) {
      print("---- insert ${g.toJson()}");
      batch.insert(
        'gestqr',
        g.toJson(), // make sure gqr_date is a string
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // --- 5. Delete missing gestQrs ---
    for (var key in toDelete) {
      batch.delete('gestqr', where: 'gqr_lemp_no = ? AND gqr_usr_no = ? AND gqr_no = ?', whereArgs: key);
    }

    // --- 6. Commit ---
    try {
      await batch.commit(noResult: true);
      print("✅ Synced: ${gestQrs.length} upserted, ${toDelete.length} deleted.");
      return gestQrs;
    } catch (e) {
      print("❌ Batch sync failed: $e");
      return [];
    }
  }

  Future<List<GestQr>> getallgestqr() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('gestqr');
    return List.generate(maps.length, (i) => GestQr.fromJson(maps[i]));
  }

  Future<List<GestQr>> getPendingGestQr() async {
    final db = await database;
    var result = await db.query('gestqr', where: 'is_uploaded = ?', whereArgs: [0]);
    return List.generate(result.length, (i) => GestQr.fromJson(result[i]));
  }

  Future<int> markGestQrAsUploaded(GestQr gestQr) async {
    final db = await database;
    return await db.update(
      'gestqr',
      {'is_uploaded': 1},
      where: 'gqr_lemp_no = ? AND gqr_usr_no = ? AND gqr_no = ?',
      whereArgs: [gestQr.gqrLempNo, gestQr.gqrUsrNo, gestQr.gqrNo],
    );
  }

  // ========================= PRODUCT METHODS =========================

  Future<List<Product>> insertAllProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    // --- 1. Incoming IDs ---
    final incomingNos = products.map((p) => p.prdNo!).toSet();

    // --- 2. Local existing IDs (fast version) ---
    final result = await db.query('products', columns: ['prd_no']);
    final localNos = result.map((e) => e['prd_no'] as String).toList();

    // --- 3. IDs to delete ---
    final toDelete = localNos.where((id) => !incomingNos.contains(id)).toList();

    // --- 4. Upsert incoming products ---
    for (var p in products) {
      print("---- insert ${p.toJson()}");
      batch.insert(
        'products',
        p.toJson(), // MUST NOT contain DateTime directly!!
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // --- 5. Delete missing products ---
    if (toDelete.isNotEmpty) {
      final placeholders = List.generate(toDelete.length, (_) => '?').join(',');
      print("---- delete in ($placeholders) values $toDelete");
      batch.delete('products', where: 'prd_no IN ($placeholders)', whereArgs: toDelete);
    }

    // --- 6. Commit ---
    try {
      await batch.commit(noResult: true);
      print("✅ Synced: ${products.length} upserted, ${toDelete.length} deleted.");
      return products;
    } catch (e) {
      print("❌ Batch sync failed: $e");
      return [];
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<List<Product>> getPendingProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: '''uploaded = ? AND (prd_qr IS NOT NULL AND prd_qr != '')''',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<int> markAsUploaded(String prdNo) async {
    final db = await database;
    return await db.update('products', {'uploaded': 1}, where: 'prd_no = ?', whereArgs: [prdNo]);
  }

  // ========================= UTILS (DEBUGGING) =========================

  Future<void> insertGestQrAndProductInTransaction(Product product, int gqrUsrNo, int gqrLempNo) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1) Compute next gqr_no by taking MAX(gqr_no) for this (lemp, usr) and adding 1
      final maxRes = await txn.rawQuery('SELECT COALESCE(MAX(gqr_no), 0) as max_no FROM gestqr WHERE gqr_lemp_no = ? AND gqr_usr_no = ?', [
        gqrLempNo,
        gqrUsrNo,
      ]);
      int nextNo = 1;
      if (maxRes.isNotEmpty) {
        final val = maxRes.first['max_no'];
        if (val is int) {
          nextNo = val + 1;
        } else {
          nextNo = (int.tryParse(val?.toString() ?? '0') ?? 0) + 1;
        }
      }
      await txn.insert("products", product.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      GestQr gestQr = GestQr(gqrLempNo: 1, gqrUsrNo: 1, gqrPrdNo: product.prdNo!, gqrNo: nextNo, gqrDate: DateTime.now(), isUploaded: 0);

      await txn.insert("gestqr", gestQr.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // Use this ONLY when you want to extract the DB for checking on PC
  // Do not use this to OPEN the database

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('products');
    await db.delete('gestqr');
    print("Database cleared");
  }

  Future<void> copyDatabaseToDownloads() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'InvontaireData.db');

      // NOTE: This path requires storage permissions on Android 10+
      final newPath = '/storage/emulated/0/Download/InvontaireData_Backup3.db';

      final file = File(path);
      if (await file.exists()) {
        await file.copy(newPath);
        print("Database successfully backed up to $newPath");
      } else {
        print("Database not found at internal path");
      }
    } catch (e) {
      print("Error copying database: $e");
    }
  }
}
