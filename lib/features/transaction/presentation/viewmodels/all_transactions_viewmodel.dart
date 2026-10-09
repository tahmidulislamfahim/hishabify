import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_model.dart';
import '../../../filter/domain/filter_model.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import 'customer_ledger_viewmodel.dart';

class AllTransactionsState {
  final List<TransactionItem> transactions;
  final TransactionFilter filter;
  final TransactionTotals? totals;
  final bool isExpandedSummary;
  final bool isLoading;

  AllTransactionsState({
    this.transactions = const [],
    this.filter = const TransactionFilter(),
    this.totals,
    this.isExpandedSummary = false,
    this.isLoading = false,
  });

  AllTransactionsState copyWith({
    List<TransactionItem>? transactions,
    TransactionFilter? filter,
    TransactionTotals? totals,
    bool? isExpandedSummary,
    bool? isLoading,
  }) {
    return AllTransactionsState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      totals: totals ?? this.totals,
      isExpandedSummary: isExpandedSummary ?? this.isExpandedSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AllTransactionsViewModel extends StateNotifier<AllTransactionsState> {
  final TransactionRepository _txRepo;
  final Ref _ref;

  AllTransactionsViewModel(this._txRepo, this._ref) : super(AllTransactionsState()) {
    loadTransactions();
    _ref.listen<ProfileState>(profileViewModelProvider, (previous, next) {
      if (previous?.activeProfile?.id != next.activeProfile?.id) {
        loadTransactions();
      }
    });
  }

  Future<void> loadTransactions() async {
    final activeProfile = _ref.read(profileViewModelProvider).activeProfile;
    if (activeProfile == null) {
      state = state.copyWith(transactions: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    final transactions = await _txRepo.getAllTransactions(
      profileId: activeProfile.id,
      filter: state.filter,
    );
    final totals = await _txRepo.getProfileTotals(activeProfile.id);

    state = state.copyWith(
      transactions: transactions,
      totals: totals,
      isLoading: false,
    );
  }

  void setFilter(TransactionFilter filter) {
    state = state.copyWith(filter: filter);
    loadTransactions();
  }

  void toggleExpandedSummary() {
    state = state.copyWith(isExpandedSummary: !state.isExpandedSummary);
  }

  Future<void> refresh() async {
    await loadTransactions();
  }
}

final allTransactionsViewModelProvider =
    StateNotifierProvider<AllTransactionsViewModel, AllTransactionsState>((ref) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  return AllTransactionsViewModel(txRepo, ref);
});
