import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer_model.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';

class CustomerListState {
  final List<Customer> customers;
  final String searchQuery;
  final CustomerSortOption sortOption;
  final bool isLoading;

  CustomerListState({
    this.customers = const [],
    this.searchQuery = '',
    this.sortOption = CustomerSortOption.byName,
    this.isLoading = false,
  });

  CustomerListState copyWith({
    List<Customer>? customers,
    String? searchQuery,
    CustomerSortOption? sortOption,
    bool? isLoading,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerListViewModel extends StateNotifier<CustomerListState> {
  final CustomerRepository _repo;
  final Ref _ref;

  CustomerListViewModel(this._repo, this._ref) : super(CustomerListState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    final activeProfile = _ref.read(profileViewModelProvider).activeProfile;
    if (activeProfile == null) {
      state = state.copyWith(customers: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    final customers = await _repo.getCustomers(
      profileId: activeProfile.id,
      searchQuery: state.searchQuery,
      sortOption: state.sortOption,
    );
    state = state.copyWith(customers: customers, isLoading: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadCustomers();
  }

  void setSortOption(CustomerSortOption option) {
    state = state.copyWith(sortOption: option);
    loadCustomers();
  }

  Future<void> refresh() async {
    await loadCustomers();
  }
}

final customerListViewModelProvider =
    StateNotifierProvider<CustomerListViewModel, CustomerListState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerListViewModel(repo, ref);
});
