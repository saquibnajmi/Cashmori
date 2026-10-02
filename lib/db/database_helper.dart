import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import '../models/borrow_model.dart';
import '../models/share_model.dart';
import '../models/asset_model.dart';

/// Singleton wrapper around the local SQLite database.
/// Every screen that stores or reads financial data goes through this class,
/// so the app has one central place for CRUD operations and refresh notifications.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;
  static const String dbName = 'money_tracker.db';

  // Signals widgets to refresh when the underlying data changes.
  final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  /// Tells listeners that data changed so they can refresh their UI.
  void notifyDataChanged() {
    refreshNotifier.value = refreshNotifier.value + 1;
  }

  /// Lazily opens the SQLite database and reuses the same connection.
  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  /// Returns the app database file path used by sqflite.
  Future<String> getDbPath() async {
    final dbDir = await getDatabasesPath();
    return join(dbDir, dbName);
  }

  // Initializes the database file and attaches the schema creation callback.
  /// Creates the database file and applies the schema creation callback.
  Future<Database> _initDb() async {
    final path = await getDbPath();
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Creates all the tables used by the finance tracker.
  /// Defines the initial database schema for transactions, borrow records, shares, and assets.
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
  /// Closes the cached database handle so a restored database can be reopened safely.
  Future<void> closeDb() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // ---------------- TRANSACTIONS ----------------

  /// Inserts a new income or expense row and then notifies the UI to refresh.
  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    final result = await db.insert('transactions', t.toMap()..remove('id'));
    notifyDataChanged();
    return result;
  }

  /// Updates an existing transaction record after the user edits it from the form sheet.
  Future<int> updateTransaction(TransactionModel t) async {
    final db = await database;
    final result = await db
        .update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    notifyDataChanged();
    return result;
  }

  /// Deletes one transaction by its primary key, then refreshes listeners.
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final result =
        await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
    return result;
  }

  /// Reads every transaction in reverse date order so the saving screen can render a timeline.
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  /// Total saving = total income - total expense, across all time.
  /// This is the metric used by the saving dashboard and by the yearly chart calculations.
  Future<double> getTotalSaving() async {
    final db = await database;

    final incomeRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income'",
    );
    final expenseRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'",
    );

    final income =
        ((incomeRows.isNotEmpty ? incomeRows.first['total'] : 0) as num?)
                ?.toDouble() ??
            0.0;
    final expense =
        ((expenseRows.isNotEmpty ? expenseRows.first['total'] : 0) as num?)
                ?.toDouble() ??
            0.0;

    return income - expense;
  }

  /// Returns 12 monthly totals for one year, indexed from January to December.
  /// This is used by the chart widget to render income, expense, and net saving trends.
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

  /// Saves a borrow/lent record and refreshes the outstanding summary in the UI.
  Future<int> insertBorrow(BorrowModel b) async {
    final db = await database;
    final result = await db.insert('borrow_records', b.toMap()..remove('id'));
    notifyDataChanged();
    return result;
  }

  /// Updates a borrow/lent item after the user marks it settled or modifies its fields.
  Future<int> updateBorrow(BorrowModel b) async {
    final db = await database;
    final result = await db.update('borrow_records', b.toMap(),
        where: 'id = ?', whereArgs: [b.id]);
    notifyDataChanged();
    return result;
  }

  /// Removes a borrow/lent entry from storage and refreshes the list.
  Future<int> deleteBorrow(int id) async {
    final db = await database;
    final result =
        await db.delete('borrow_records', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
    return result;
  }

  /// Loads all borrow/lent records ordered newest first for the outstanding summary screen.
  Future<List<BorrowModel>> getAllBorrowRecords() async {
    final db = await database;
    final rows = await db.query('borrow_records', orderBy: 'date DESC');
    return rows.map((r) => BorrowModel.fromMap(r)).toList();
  }

  // ---------------- SHARES ----------------

  /// Inserts a new share position into the portfolio database.
  Future<int> insertShare(ShareModel s) async {
    final db = await database;
    final result = await db.insert('shares', s.toMap()..remove('id'));
    notifyDataChanged();
    return result;
  }

  /// Updates a saved share position after the user edits the investment details.
  Future<int> updateShare(ShareModel s) async {
    final db = await database;
    final result = await db
        .update('shares', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    notifyDataChanged();
    return result;
  }

  /// Deletes a share entry and refreshes the portfolio card values immediately.
  Future<int> deleteShare(int id) async {
    final db = await database;
    final result = await db.delete('shares', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
    return result;
  }

  /// Reads all share investments sorted by company name for the portfolio screen.
  Future<List<ShareModel>> getAllShares() async {
    final db = await database;
    final rows = await db.query('shares', orderBy: 'company_name ASC');
    return rows.map((r) => ShareModel.fromMap(r)).toList();
  }

  // ---------------- ASSETS ----------------

  /// Saves a long-term asset like property, gold, or a vehicle into the database.
  Future<int> insertAsset(AssetModel a) async {
    final db = await database;
    final result = await db.insert('assets', a.toMap()..remove('id'));
    notifyDataChanged();
    return result;
  }

  /// Updates an asset record after the user changes its value or metadata.
  Future<int> updateAsset(AssetModel a) async {
    final db = await database;
    final result = await db
        .update('assets', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
    notifyDataChanged();
    return result;
  }

  /// Deletes one asset and updates all balance-related screens immediately.
  Future<int> deleteAsset(int id) async {
    final db = await database;
    final result = await db.delete('assets', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
    return result;
  }

  /// Loads all assets sorted by type so the asset screen can group and display them clearly.
  Future<List<AssetModel>> getAllAssets() async {
    final db = await database;
    final rows = await db.query('assets', orderBy: 'asset_type ASC');
    return rows.map((r) => AssetModel.fromMap(r)).toList();
  }
}
