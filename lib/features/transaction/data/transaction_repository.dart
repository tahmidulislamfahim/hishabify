import '../../../core/database/app_database.dart';
import '../../filter/domain/filter_model.dart';
import '../domain/transaction_model.dart';

class TransactionTotals {
  final double totalCredit;
  final double totalPayment;
  final int creditCount;
  final int paymentCount;

  TransactionTotals({
    required this.totalCredit,
    required this.totalPayment,
    required this.creditCount,
    required this.paymentCount,
  });

  double get netBalance => totalCredit - totalPayment;
}

class TransactionRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<TransactionItem>> getCustomerTransactions(String customerId) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date_time DESC',
    );
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  Future<TransactionTotals> getCustomerTotals(String customerId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) as total_credit,
        COALESCE(SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END), 0) as total_payment,
        COUNT(CASE WHEN type = 'credit' THEN 1 END) as credit_count,
        COUNT(CASE WHEN type = 'payment' THEN 1 END) as payment_count
      FROM transactions
      WHERE customer_id = ?
    ''', [customerId]);

    if (results.isEmpty) {
      return TransactionTotals(
        totalCredit: 0,
        totalPayment: 0,
        creditCount: 0,
        paymentCount: 0,
      );
    }

    final row = results.first;
    return TransactionTotals(
      totalCredit: (row['total_credit'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (row['total_payment'] as num?)?.toDouble() ?? 0.0,
      creditCount: (row['credit_count'] as int?) ?? 0,
      paymentCount: (row['payment_count'] as int?) ?? 0,
    );
  }

  Future<TransactionTotals> getProfileTotals(String profileId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) as total_credit,
        COALESCE(SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END), 0) as total_payment,
        COUNT(CASE WHEN type = 'credit' THEN 1 END) as credit_count,
        COUNT(CASE WHEN type = 'payment' THEN 1 END) as payment_count
      FROM transactions
      WHERE profile_id = ?
    ''', [profileId]);

    if (results.isEmpty) {
      return TransactionTotals(
        totalCredit: 0,
        totalPayment: 0,
        creditCount: 0,
        paymentCount: 0,
      );
    }

    final row = results.first;
    return TransactionTotals(
      totalCredit: (row['total_credit'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (row['total_payment'] as num?)?.toDouble() ?? 0.0,
      creditCount: (row['credit_count'] as int?) ?? 0,
      paymentCount: (row['payment_count'] as int?) ?? 0,
    );
  }

  Future<List<TransactionItem>> getAllTransactions({
    required String profileId,
    TransactionFilter? filter,
  }) async {
    final db = await _db.database;

    String whereClause = 't.profile_id = ?';
    List<dynamic> whereArgs = [profileId];

    if (filter != null) {
      // Customer filter
      if (filter.selectedCustomerId != null) {
        whereClause += ' AND t.customer_id = ?';
        whereArgs.add(filter.selectedCustomerId);
      }

      // Transaction type filter
      if (filter.typeFilter == FilterTypeOption.credits) {
        whereClause += " AND t.type = 'credit'";
      } else if (filter.typeFilter == FilterTypeOption.payments) {
        whereClause += " AND t.type = 'payment'";
      }

      // Date range filter
      final dateRange = filter.effectiveDateRange;
      if (dateRange != null) {
        whereClause += ' AND t.date_time >= ? AND t.date_time <= ?';
        whereArgs.add(dateRange.start.toIso8601String());
        whereArgs.add(dateRange.end.toIso8601String());
      }
    }

    final query = '''
      SELECT 
        t.*, 
        c.name as customer_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE $whereClause
      ORDER BY t.date_time DESC
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  Future<void> saveTransaction(TransactionItem tx) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'transactions',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [tx.id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.update(
          'transactions',
          tx.toMap(),
          where: 'id = ?',
          whereArgs: [tx.id],
        );
      } else {
        await txn.insert('transactions', tx.toMap());
      }

      // Update customer updated_at
      await txn.update(
        'customers',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [tx.customerId],
      );
    });
  }

  Future<void> deleteTransaction(String transactionId, String customerId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
      await txn.update(
        'customers',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });
  }
}
