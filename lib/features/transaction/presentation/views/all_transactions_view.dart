import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../filter/domain/filter_model.dart';
import '../../../filter/presentation/views/transaction_filter_view.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/transaction_model.dart';
import '../viewmodels/all_transactions_viewmodel.dart';
import 'add_edit_transaction_view.dart';

class AllTransactionsView extends ConsumerStatefulWidget {
  const AllTransactionsView({super.key});

  @override
  ConsumerState<AllTransactionsView> createState() => _AllTransactionsViewState();
}

class _AllTransactionsViewState extends ConsumerState<AllTransactionsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allTransactionsViewModelProvider.notifier).loadTransactions();
    });
  }

  void _openFilter() async {
    final currentFilter = ref.read(allTransactionsViewModelProvider).filter;
    final result = await Navigator.of(context).push<TransactionFilter>(
      MaterialPageRoute(
        builder: (_) => TransactionFilterView(currentFilter: currentFilter),
      ),
    );

    if (result != null) {
      ref.read(allTransactionsViewModelProvider.notifier).setFilter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(allTransactionsViewModelProvider);
    final profile = ref.watch(profileViewModelProvider).activeProfile;
    final currency = profile?.currency ?? '\$';
    final settings = ref.watch(settingsViewModelProvider).settings;
    final dateFormat = settings.dateFormat;
    final timeFormat = settings.timeFormat;

    final totals = txState.totals;
    final netBalance = totals?.netBalance ?? 0.0;
    final isDue = netBalance > 0;
    final isAdvance = netBalance < 0;

    final hasActiveFilter = txState.filter.dateMode != DateFilterMode.quickAccess ||
        txState.filter.quickDate != QuickDateOption.all ||
        txState.filter.typeFilter != FilterTypeOption.all ||
        txState.filter.selectedCustomerId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _openFilter,
                tooltip: 'Filter',
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Net Balance Summary Card
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    ref.read(allTransactionsViewModelProvider.notifier).toggleExpandedSummary();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL NET BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatCurrency(netBalance.abs(), currency: currency),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDue
                                    ? AppColors.creditRed
                                    : (isAdvance ? AppColors.paymentGreen : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDue
                                    ? AppColors.creditRedLight
                                    : (isAdvance ? AppColors.paymentGreenLight : AppColors.cardBackground),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isDue ? 'DUE' : (isAdvance ? 'ADVANCE' : 'SETTLED'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDue
                                      ? AppColors.creditRed
                                      : (isAdvance ? AppColors.paymentGreen : AppColors.textSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              txState.isExpandedSummary
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Collapsible detailed totals
                if (txState.isExpandedSummary && totals != null) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.paymentGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${totals.paymentCount} Payments',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppFormatters.formatCurrency(totals.totalPayment, currency: currency),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.paymentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 36, width: 1, color: AppColors.divider),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.creditRed),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${totals.creditCount} Credits',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(totals.totalCredit, currency: currency),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.creditRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Active Filter Chips
          if (hasActiveFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Filtered Transactions',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(allTransactionsViewModelProvider.notifier).setFilter(const TransactionFilter());
                    },
                    child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // Transactions List or Empty State
          Expanded(
            child: txState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : txState.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 34),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Transactions Found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No transactions match the selected filter.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => ref.read(allTransactionsViewModelProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: txState.transactions.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final tx = txState.transactions[index];
                            final isPayment = tx.type == TransactionType.payment;
                            final formattedDate = AppFormatters.formatDateTime(
                              tx.dateTime,
                              dateFormat: dateFormat,
                              timeFormat: timeFormat,
                            );

                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditTransactionView(
                                      customerId: tx.customerId,
                                      existingTransaction: tx,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.customerName ?? 'Customer',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                          if (tx.note != null && tx.note!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              tx.note!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppFormatters.formatCurrency(tx.amount, currency: currency),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isPayment ? AppColors.paymentGreen : AppColors.creditRed,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isPayment ? 'Payment' : 'Credit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isPayment ? AppColors.paymentGreen : AppColors.creditRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
