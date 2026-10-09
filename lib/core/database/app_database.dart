import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('credit_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Profiles table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        carry_forward_balance REAL NOT NULL DEFAULT 0.0,
        carry_forward_type TEXT NOT NULL DEFAULT 'credit',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // 3. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date_time TEXT NOT NULL,
        note TEXT,
        is_carry_forward INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // 4. Settings table (key-value)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 5. Exported Reports table
    await db.execute('''
      CREATE TABLE exported_reports (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {'key': 'app_lock_enabled', 'value': 'false'});
    await db.insert('settings', {'key': 'date_format', 'value': 'dd MMM yyyy'});
    await db.insert('settings', {'key': 'time_format', 'value': 'hh:mm a'});
    await db.insert('settings', {'key': 'default_currency', 'value': '\$'});
    await db.insert('settings', {'key': 'disclosed_terms', 'value': 'false'});
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('customers');
      await txn.delete('profiles');
      await txn.delete('exported_reports');
      // Reset settings to defaults except terms disclosure
      await txn.update(
        'settings',
        {'value': 'false'},
        where: 'key = ?',
        whereArgs: ['app_lock_enabled'],
      );
      await txn.update(
        'settings',
        {'value': 'dd MMM yyyy'},
        where: 'key = ?',
        whereArgs: ['date_format'],
      );
      await txn.update(
        'settings',
        {'value': 'hh:mm a'},
        where: 'key = ?',
        whereArgs: ['time_format'],
      );
      await txn.update(
        'settings',
        {'value': '\$'},
        where: 'key = ?',
        whereArgs: ['default_currency'],
      );
    });
  }

  /// Exports the entire database as a JSON map for local backup
  Future<Map<String, dynamic>> exportBackupJson() async {
    final db = await database;
    final profiles = await db.query('profiles');
    final customers = await db.query('customers');
    final transactions = await db.query('transactions');
    final settings = await db.query('settings');

    return {
      'app': 'Hishabify',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'profiles': profiles,
      'customers': customers,
      'transactions': transactions,
      'settings': settings,
    };
  }

  /// Restores the database from an exported JSON map
  Future<bool> restoreFromBackupJson(Map<String, dynamic> backupData) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('customers');
        await txn.delete('profiles');

        final profiles = backupData['profiles'] as List<dynamic>? ?? [];
        for (final p in profiles) {
          await txn.insert('profiles', Map<String, dynamic>.from(p));
        }

        final customers = backupData['customers'] as List<dynamic>? ?? [];
        for (final c in customers) {
          await txn.insert('customers', Map<String, dynamic>.from(c));
        }

        final transactions = backupData['transactions'] as List<dynamic>? ?? [];
        for (final t in transactions) {
          await txn.insert('transactions', Map<String, dynamic>.from(t));
        }

        final settings = backupData['settings'] as List<dynamic>? ?? [];
        for (final s in settings) {
          final sMap = Map<String, dynamic>.from(s);
          await txn.insert(
            'settings',
            sMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Ensure terms are marked as disclosed in the key-value settings table
        await txn.insert(
          'settings',
          {'key': 'disclosed_terms', 'value': 'true'},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final defaultProfilesCount = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM profiles WHERE is_default = 1'),
        ) ?? 0;
        if (defaultProfilesCount == 0 && profiles.isNotEmpty) {
          final firstProfileId = (profiles.first as Map)['id'];
          if (firstProfileId != null) {
            await txn.update(
              'profiles',
              {'is_default': 1},
              where: 'id = ?',
              whereArgs: [firstProfileId],
            );
          }
        }
      });
      return true;
    } catch (e, stack) {
      debugPrint('Restore error in AppDatabase: $e\n$stack');
      return false;
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
