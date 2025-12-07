import 'dart:io';
import 'package:invontaire_local/data/model/invontaie_model.dart';
import 'package:invontaire_local/data/model/product_model.dart';
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

    print("Database path = $path");

    // 2. Open the database
    return await openDatabase(
      '/storage/emulated/0/Download/data/db2.db',
      // path,
      version: 2, // Incremented version to trigger upgrade
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_qr ON products(prd_qr)',
    );
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

    // 3. Create Invontaies Table
    await db.execute('''
      CREATE TABLE invontaie (
        inv_no INTEGER PRIMARY KEY AUTOINCREMENT,
        inv_lemp_no INTEGER,
        inv_lemp_nom TEXT,
        inv_pntg_no INTEGER,
        inv_pntg_nom TEXT,
        inv_usr_no INTEGER,
        inv_usr_nom TEXT,
        inv_prd_no TEXT,
        inv_prd_nom TEXT,
        inv_exp TEXT,
        inv_date TEXT,
        is_uploaded INTEGER DEFAULT 0
      )
    ''');
    print("------- created all tables successfully -------");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 2) {
      // Create gestqr table if it doesn't exist
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
      print("Created gestqr table");

      // Create invontaie table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invontaie (
          inv_no INTEGER PRIMARY KEY AUTOINCREMENT,
          inv_lemp_no INTEGER,
          inv_pntg_no INTEGER,
          inv_usr_no INTEGER,
          inv_prd_no TEXT,
          inv_exp TEXT,
          inv_date TEXT,
          is_uploaded INTEGER DEFAULT 0
        )
      ''');
      print("Created invontaie table");

      // Add is_uploaded column to products if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN uploaded INTEGER DEFAULT 0',
        );
        print("Added uploaded column to products table");
      } catch (e) {
        print("uploaded column already exists in products table or error: $e");
      }

      print("Upgraded DB to version 2");
    }
  }

  // ========================= GEST QR METHODS =========================

  Future<List<GestQr>> insertAllGestqr(List<GestQr> gestQrs) async {
    final db = await database;
    final batch = db.batch();

    // --- 1. Incoming composite keys ---
    final incomingKeys = gestQrs
        .map((g) => [g.gqrLempNo, g.gqrUsrNo, g.gqrNo])
        .toList();

    // --- 2. Local existing keys ---
    final result = await db.query(
      'gestqr',
      columns: ['gqr_lemp_no', 'gqr_usr_no', 'gqr_no'],
    );
    final localKeys = result
        .map(
          (e) => [
            e['gqr_lemp_no'] as int,
            e['gqr_usr_no'] as int,
            e['gqr_no'] as int,
          ],
        )
        .toList();

    // --- 3. Keys to delete ---
    final toDelete = localKeys
        .where(
          (localKey) => !incomingKeys.any(
            (incKey) =>
                incKey[0] == localKey[0] &&
                incKey[1] == localKey[1] &&
                incKey[2] == localKey[2],
          ),
        )
        .toList();

    // --- 4. Upsert incoming gestQrs ---
    for (var g in gestQrs) {
      batch.insert(
        'gestqr',
        g.toJson(), // make sure gqr_date is a string
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // --- 5. Delete missing gestQrs ---
    for (var key in toDelete) {
      batch.delete(
        'gestqr',
        where: 'gqr_lemp_no = ? AND gqr_usr_no = ? AND gqr_no = ?',
        whereArgs: key,
      );
    }

    // --- 6. Commit ---
    try {
      await batch.commit(noResult: true);
      print(
        "✅ Gestqr Synced: ${gestQrs.length} upserted, ${toDelete.length} deleted.",
      );
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
    var result = await db.query(
      'gestqr',
      where: 'is_uploaded = ?',
      whereArgs: [0],
    );
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
      batch.insert(
        'products',
        p.toJson(), // MUST NOT contain DateTime directly!!
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // --- 5. Delete missing products ---
    if (toDelete.isNotEmpty) {
      final placeholders = List.generate(toDelete.length, (_) => '?').join(',');
      batch.delete(
        'products',
        where: 'prd_no IN ($placeholders)',
        whereArgs: toDelete,
      );
    }

    // --- 6. Commit ---
    try {
      await batch.commit(noResult: true);
      print(
        "✅ Products Synced: ${products.length} upserted, ${toDelete.length} deleted.",
      );
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

  Future<int> markProductAsUploaded(String prdNo) async {
    final db = await database;
    return await db.update(
      'products',
      {'uploaded': 1},
      where: 'prd_no = ?',
      whereArgs: [prdNo],
    );
  }

  // ========================= Invontaire METHODS =========================

  Future<List<Invontaie>> insertAllInvontaie(List<Invontaie> invontaies) async {
    final db = await database;
    final batch = db.batch();

    // --- 1. Incoming IDs ---
    final incomingNos = invontaies.map((p) => p.invNo!).toSet();

    // --- 2. Local existing IDs (fast version) ---
    final result = await db.query('invontaie', columns: ['inv_no']);
    final localNos = result.map((e) => e['inv_no'] as int).toList();

    // --- 3. IDs to delete ---
    final toDelete = localNos.where((id) => !incomingNos.contains(id)).toList();

    // --- 4. Upsert incoming products ---
    for (var p in invontaies) {
      batch.insert(
        'invontaie',
        p.toJson(), // MUST NOT contain DateTime directly!!
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // --- 5. Delete missing products ---
    if (toDelete.isNotEmpty) {
      final placeholders = List.generate(toDelete.length, (_) => '?').join(',');
      batch.delete(
        'invontaie',
        where: 'inv_no IN ($placeholders)',
        whereArgs: toDelete,
      );
    }

    // --- 6. Commit ---
    try {
      await batch.commit(noResult: true);
      print(
        "✅ Invontaies Synced: ${invontaies.length} upserted, ${toDelete.length} deleted.",
      );
      return invontaies;
    } catch (e) {
      print("❌ Batch sync failed: $e");
      return [];
    }
  }

  Future<List<Invontaie>> getAllInvontaies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('invontaie');
    return List.generate(maps.length, (i) => Invontaie.fromJson(maps[i]));
  }

  Future<List<Invontaie>> getPendingInvontaies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invontaie',
      where: 'is_uploaded = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Invontaie.fromJson(maps[i]));
  }

  Future<int> markInvontaieAsUploaded(int invNo) async {
    final db = await database;
    return await db.update(
      'invontaie',
      {'is_uploaded': 1},
      where: 'inv_no = ?',
      whereArgs: [invNo],
    );
  }

  /// Insert or update a single Invontaie record
  Future<int?> insertOrUpdateInvontaie(Invontaie invontaie) async {
    final db = await database;
    try {
      final id = await db.insert(
        'invontaie',
        invontaie.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Invontaie saved locally with id: $id");
      return id;
    } catch (e) {
      print("Error saving invontaie locally: $e");
      return null;
    }
  }

  // ========================= UTILS (DEBUGGING) =========================

  Future<void> insertGestQrAndProductInTransaction(
    Product product,
    int gqrUsrNo,
    int gqrLempNo,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      // Compute next gqr_no directly in SQL
      final result = await txn.rawQuery(
        '''
      SELECT COALESCE(MAX(gqr_no), 0) + 1 as nextNo
      FROM gestqr
      WHERE gqr_lemp_no = ? AND gqr_usr_no = ?
      ''',
        [gqrLempNo, gqrUsrNo],
      );
      int nextNo = result.first['nextNo'] as int;

      // Insert or replace product
      await txn.insert(
        'products',
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert gestqr
      final gestQr = GestQr(
        gqrLempNo: gqrLempNo,
        gqrUsrNo: gqrUsrNo,
        gqrPrdNo: product.prdNo!,
        gqrNo: nextNo,
        gqrDate: DateTime.now(),
        isUploaded: 0,
      );

      await txn.insert(
        'gestqr',
        gestQr.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
