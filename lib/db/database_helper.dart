import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import '../models/borrow_model.dart';
import '../models/share_model.dart';
import '../models/asset_model.dart';

/// Singleton wrapper around the sqflite database.
/// All four "hub" pages (Saving, Borrow & Outstanding, Shares, Assets)
/// read/write through this one class.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;
  static const String dbName = 'money_tracker.db';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<String> getDbPath() async {
    final dbDir = await getDatabasesPath();
    return join(dbDir, dbName);
  }

  Future<Database> _initDb() async {
    final path = await getDbPath();
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE borrow_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        due_date TEXT,
        status TEXT NOT NULL DEFAULT 'outstanding',
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        buy_price REAL NOT NULL,
        current_price REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        value REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  /// Closes and clears the cached db handle. Needed before/after a restore
  /// so the newly-copied file is reopened cleanly.
  Future<void> closeDb() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // ---------------- TRANSACTIONS ----------------

  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    return db.insert('transactions', t.toMap()..remove('id'));
  }

  Future<int> updateTransaction(TransactionModel t) async {
    final db = await database;
    return db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  /// Total saving = total income - total expense, across all time.
  Future<double> getTotalSaving() async {
    final db = await database;
    final income = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT IFNULL(SUM(amount),0) as s FROM transactions WHERE type = 'income'")) ??
        0;
    final expense = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT IFNULL(SUM(amount),0) as s FROM transactions WHERE type = 'expense'")) ??
        0;
    return (income - expense).toDouble();
  }

  /// Returns 12 monthly totals (index 0 = Jan ... 11 = Dec) for the given
  /// year, used to draw the Saving / Income / Expense line chart.
  Future<Map<String, List<double>>> getMonthlyTotals(int year) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT strftime('%m', date) as month, type, SUM(amount) as total
      FROM transactions
      WHERE strftime('%Y', date) = ?
      GROUP BY month, type
    ''', [year.toString()]);

    final income = List<double>.filled(12, 0);
    final expense = List<double>.filled(12, 0);
    for (final row in rows) {
      final monthIndex = int.parse(row['month'] as String) - 1;
      final total = (row['total'] as num).toDouble();
      if (row['type'] == 'income') {
        income[monthIndex] = total;
      } else {
        expense[monthIndex] = total;
      }
    }
    final saving = List<double>.generate(12, (i) => income[i] - expense[i]);
    return {'income': income, 'expense': expense, 'saving': saving};
  }

  // ---------------- BORROW & OUTSTANDING ----------------

  Future<int> insertBorrow(BorrowModel b) async {
    final db = await database;
    return db.insert('borrow_records', b.toMap()..remove('id'));
  }

  Future<int> updateBorrow(BorrowModel b) async {
    final db = await database;
    return db.update('borrow_records', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> deleteBorrow(int id) async {
    final db = await database;
    return db.delete('borrow_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BorrowModel>> getAllBorrowRecords() async {
    final db = await database;
    final rows = await db.query('borrow_records', orderBy: 'date DESC');
    return rows.map((r) => BorrowModel.fromMap(r)).toList();
  }

  // ---------------- SHARES ----------------

  Future<int> insertShare(ShareModel s) async {
    final db = await database;
    return db.insert('shares', s.toMap()..remove('id'));
  }

  Future<int> updateShare(ShareModel s) async {
    final db = await database;
    return db.update('shares', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteShare(int id) async {
    final db = await database;
    return db.delete('shares', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ShareModel>> getAllShares() async {
    final db = await database;
    final rows = await db.query('shares', orderBy: 'company_name ASC');
    return rows.map((r) => ShareModel.fromMap(r)).toList();
  }

  // ---------------- ASSETS ----------------

  Future<int> insertAsset(AssetModel a) async {
    final db = await database;
    return db.insert('assets', a.toMap()..remove('id'));
  }

  Future<int> updateAsset(AssetModel a) async {
    final db = await database;
    return db.update('assets', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<int> deleteAsset(int id) async {
    final db = await database;
    return db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AssetModel>> getAllAssets() async {
    final db = await database;
    final rows = await db.query('assets', orderBy: 'asset_type ASC');
    return rows.map((r) => AssetModel.fromMap(r)).toList();
  }
}
