import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../core/utils/formatters.dart';
import '../../../customer/presentation/views/add_edit_customer_view.dart';
import '../../../customer/presentation/views/customer_detail_view.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../reports/presentation/views/filter_report_view.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/transaction_model.dart';
import '../viewmodels/customer_ledger_viewmodel.dart';
import 'add_edit_transaction_view.dart';

class CustomerLedgerView extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerLedgerView({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerLedgerView> createState() => _CustomerLedgerViewState();
}

class _CustomerLedgerViewState extends ConsumerState<CustomerLedgerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerLedgerViewModelProvider(widget.customerId).notifier).loadLedger();
    });
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppDialogs.showToast(context, 'Cannot open phone dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerState = ref.watch(customerLedgerViewModelProvider(widget.customerId));
    final profile = ref.watch(profileViewModelProvider).activeProfile;
    final currency = profile?.currency ?? '\$';
    final settings = ref.watch(settingsViewModelProvider).settings;
    final dateFormat = settings.dateFormat;
    final timeFormat = settings.timeFormat;

    final customer = ledgerState.customer;
    if (customer == null && ledgerState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Ledger')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final totals = ledgerState.totals;
    final netBalance = totals?.netBalance ?? 0.0;
    final isDue = netBalance > 0;
    final isAdvance = netBalance < 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Text(
                customer.phone!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerDetailView(customer: customer),
                ),
              );
              ref.read(customerLedgerViewModelProvider(widget.customerId).notifier).loadLedger();
            },
            tooltip: 'Customer Info',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditCustomerView(existingCustomer: customer),
                ),
              );
              ref.read(customerLedgerViewModelProvider(widget.customerId).notifier).loadLedger();
            },
            tooltip: 'Edit Customer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Expandable Net Balance Card
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
                    ref.read(customerLedgerViewModelProvider(widget.customerId).notifier).toggleExpandedSummary();
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
                              'NET BALANCE',
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
                              ledgerState.isExpandedSummary
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

                // Collapsible detailed breakdown
                if (ledgerState.isExpandedSummary && totals != null) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Payment breakdown
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
                        // Credit breakdown
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

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DATE & TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PAYMENT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.paymentGreen,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CREDIT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.creditRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Transactions List
          Expanded(
            child: ledgerState.transactions.isEmpty
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
                          child: const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Transactions Yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap Give Credit or Accept Payment below',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: ledgerState.transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final tx = ledgerState.transactions[index];
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
                                customerId: widget.customerId,
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
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
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
                              Expanded(
                                flex: 2,
                                child: Text(
                                  isPayment ? AppFormatters.formatCurrency(tx.amount, currency: currency) : '-',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isPayment ? AppColors.paymentGreen : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  !isPayment ? AppFormatters.formatCurrency(tx.amount, currency: currency) : '-',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: !isPayment ? AppColors.creditRed : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Call button
                  if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                      onPressed: () => _callPhone(customer.phone!),
                      tooltip: 'Call Customer',
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Report / Share button
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FilterReportView(customer: customer),
                        ),
                      );
                    },
                    tooltip: 'Report / Statement',
                  ),
                  const SizedBox(width: 8),

                  // Accept Payment button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paymentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                      label: const Text(
                        'ACCEPT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditTransactionView(
                              customerId: widget.customerId,
                              initialType: TransactionType.payment,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Give Credit button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.creditRed,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                      label: const Text(
                        'GIVE CREDIT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditTransactionView(
                              customerId: widget.customerId,
                              initialType: TransactionType.credit,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
