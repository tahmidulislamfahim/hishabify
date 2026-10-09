import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_model.dart';
import '../../../customer/data/customer_repository.dart';
import '../../../customer/domain/customer_model.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';

class CustomerLedgerState {
  final Customer? customer;
  final List<TransactionItem> transactions;
  final TransactionTotals? totals;
  final bool isExpandedSummary;
  final bool isLoading;

  CustomerLedgerState({
    this.customer,
    this.transactions = const [],
    this.totals,
    this.isExpandedSummary = false,
    this.isLoading = false,
  });

  CustomerLedgerState copyWith({
    Customer? customer,
    List<TransactionItem>? transactions,
    TransactionTotals? totals,
    bool? isExpandedSummary,
    bool? isLoading,
  }) {
    return CustomerLedgerState(
      customer: customer ?? this.customer,
      transactions: transactions ?? this.transactions,
      totals: totals ?? this.totals,
      isExpandedSummary: isExpandedSummary ?? this.isExpandedSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class CustomerLedgerViewModel extends StateNotifier<CustomerLedgerState> {
  final TransactionRepository txRepo;
  final CustomerRepository custRepo;
  final String customerId;

  CustomerLedgerViewModel({
    required this.txRepo,
    required this.custRepo,
    required this.customerId,
  }) : super(CustomerLedgerState()) {
    loadLedger();
  }

  Future<void> loadLedger() async {
    state = state.copyWith(isLoading: true);
    final customer = await custRepo.getCustomerById(customerId);
    final transactions = await txRepo.getCustomerTransactions(customerId);
    final totals = await txRepo.getCustomerTotals(customerId);

    state = state.copyWith(
      customer: customer,
      transactions: transactions,
      totals: totals,
      isLoading: false,
    );
  }

  void toggleExpandedSummary() {
    state = state.copyWith(isExpandedSummary: !state.isExpandedSummary);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await txRepo.deleteTransaction(transactionId, customerId);
    await loadLedger();
  }
}

final customerLedgerViewModelProvider =
    StateNotifierProvider.family<CustomerLedgerViewModel, CustomerLedgerState, String>(
  (ref, customerId) {
    final txRepo = ref.watch(transactionRepositoryProvider);
    final custRepo = ref.watch(customerRepositoryProvider);
    return CustomerLedgerViewModel(
      txRepo: txRepo,
      custRepo: custRepo,
      customerId: customerId,
    );
  },
);
