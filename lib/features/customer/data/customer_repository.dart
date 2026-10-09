import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../transaction/domain/transaction_model.dart';
import '../domain/customer_model.dart';

enum CustomerSortOption {
  byName,
  amountMost,
  amountLeast,
  mostRecent;

  String get displayName {
    switch (this) {
      case CustomerSortOption.byName:
        return 'By Name';
      case CustomerSortOption.amountMost:
        return 'Amount Most';
      case CustomerSortOption.amountLeast:
        return 'Amount Least';
      case CustomerSortOption.mostRecent:
        return 'Most Recent';
    }
  }
}

class CustomerRepository {
  final AppDatabase _db = AppDatabase.instance;
  final _uuid = const Uuid();

  Future<List<Customer>> getCustomers({
    required String profileId,
    String? searchQuery,
    CustomerSortOption sortOption = CustomerSortOption.byName,
  }) async {
    final db = await _db.database;

    final customerMaps = await db.query(
      'customers',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );

    final List<Customer> customers = [];

    for (final cMap in customerMaps) {
      final customerId = cMap['id'] as String;

      // Query transaction totals
      final txResults = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) as total_credit,
          COALESCE(SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END), 0) as total_payment,
          MAX(date_time) as last_tx_date
        FROM transactions
        WHERE customer_id = ?
      ''', [customerId]);

      double totalCredit = 0.0;
      double totalPayment = 0.0;
      DateTime? lastTxDate;

      if (txResults.isNotEmpty) {
        final row = txResults.first;
        totalCredit = (row['total_credit'] as num?)?.toDouble() ?? 0.0;
        totalPayment = (row['total_payment'] as num?)?.toDouble() ?? 0.0;
        final rawDate = row['last_tx_date'] as String?;
        if (rawDate != null) {
          lastTxDate = DateTime.tryParse(rawDate);
        }
      }

      final customer = Customer.fromMap(
        cMap,
        totalCredit: totalCredit,
        totalPayment: totalPayment,
        lastTransactionDate: lastTxDate ?? DateTime.parse(cMap['updated_at'] as String),
      );

      // Search filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesName = customer.name.toLowerCase().contains(q);
        final matchesPhone = (customer.phone ?? '').toLowerCase().contains(q);
        if (!matchesName && !matchesPhone) {
          continue;
        }
      }

      customers.add(customer);
    }

    // Sort customers
    switch (sortOption) {
      case CustomerSortOption.byName:
        customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CustomerSortOption.amountMost:
        customers.sort((a, b) => b.netBalance.compareTo(a.netBalance));
        break;
      case CustomerSortOption.amountLeast:
        customers.sort((a, b) => a.netBalance.compareTo(b.netBalance));
        break;
      case CustomerSortOption.mostRecent:
        customers.sort((a, b) {
          final dateA = a.lastTransactionDate ?? a.createdAt;
          final dateB = b.lastTransactionDate ?? b.createdAt;
          return dateB.compareTo(dateA);
        });
        break;
    }

    return customers;
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final db = await _db.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final txResults = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) as total_credit,
        COALESCE(SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END), 0) as total_payment,
        MAX(date_time) as last_tx_date
      FROM transactions
      WHERE customer_id = ?
    ''', [customerId]);

    double totalCredit = 0.0;
    double totalPayment = 0.0;
    DateTime? lastTxDate;

    if (txResults.isNotEmpty) {
      final row = txResults.first;
      totalCredit = (row['total_credit'] as num?)?.toDouble() ?? 0.0;
      totalPayment = (row['total_payment'] as num?)?.toDouble() ?? 0.0;
      final rawDate = row['last_tx_date'] as String?;
      if (rawDate != null) {
        lastTxDate = DateTime.tryParse(rawDate);
      }
    }

    return Customer.fromMap(
      maps.first,
      totalCredit: totalCredit,
      totalPayment: totalPayment,
      lastTransactionDate: lastTxDate ?? DateTime.parse(maps.first['updated_at'] as String),
    );
  }

  Future<void> saveCustomer(Customer customer, {bool isNew = true}) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      if (isNew) {
        await txn.insert('customers', customer.toMap());

        // If new customer with carry forward balance > 0, insert initial transaction
        if (customer.carryForwardBalance > 0) {
          final tx = TransactionItem(
            id: _uuid.v4(),
            profileId: customer.profileId,
            customerId: customer.id,
            amount: customer.carryForwardBalance,
            type: customer.carryForwardType,
            dateTime: customer.createdAt,
            note: 'Carry Forward Balance',
            isCarryForward: true,
          );
          await txn.insert('transactions', tx.toMap());
        }
      } else {
        await txn.update(
          'customers',
          customer.toMap(),
          where: 'id = ?',
          whereArgs: [customer.id],
        );
      }
    });
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _db.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> settleAndDeleteCustomer(String customerId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'customer_id = ?', whereArgs: [customerId]);
      await txn.delete('customers', where: 'id = ?', whereArgs: [customerId]);
    });
  }
}
