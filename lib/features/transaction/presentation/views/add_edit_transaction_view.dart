import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/transaction_model.dart';
import '../viewmodels/all_transactions_viewmodel.dart';
import '../viewmodels/customer_ledger_viewmodel.dart';

class AddEditTransactionView extends ConsumerStatefulWidget {
  final String customerId;
  final TransactionType initialType;
  final TransactionItem? existingTransaction;

  const AddEditTransactionView({
    super.key,
    required this.customerId,
    this.initialType = TransactionType.credit,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddEditTransactionView> createState() => _AddEditTransactionViewState();
}

class _AddEditTransactionViewState extends ConsumerState<AddEditTransactionView> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _type = tx.type;
      _amountController.text = tx.amount == tx.amount.roundToDouble()
          ? tx.amount.toInt().toString()
          : tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _selectedDateTime = tx.dateTime;
    } else {
      _type = widget.initialType;
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _type == TransactionType.credit ? AppColors.creditRed : AppColors.paymentGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _type == TransactionType.credit ? AppColors.creditRed : AppColors.paymentGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      AppDialogs.showToast(context, 'Please enter Amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      AppDialogs.showToast(context, 'Please enter valid Amount');
      return;
    }

    final activeProfile = ref.read(profileViewModelProvider).activeProfile;
    if (activeProfile == null) {
      AppDialogs.showToast(context, 'No active profile found');
      return;
    }

    final note = _noteController.text.trim();

    final tx = TransactionItem(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      profileId: activeProfile.id,
      customerId: widget.customerId,
      amount: amount,
      type: _type,
      dateTime: _selectedDateTime,
      note: note.isNotEmpty ? note : null,
      isCarryForward: widget.existingTransaction?.isCarryForward ?? false,
    );

    await ref.read(transactionRepositoryProvider).saveTransaction(tx);

    // Refresh view models
    await ref.read(customerLedgerViewModelProvider(widget.customerId).notifier).loadLedger();
    await ref.read(customerListViewModelProvider.notifier).loadCustomers();
    await ref.read(allTransactionsViewModelProvider.notifier).loadTransactions();

    if (mounted) {
      AppDialogs.showToast(
        context,
        widget.existingTransaction != null ? 'Transaction updated' : 'Transaction saved',
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction entry?',
      confirmText: 'DELETE',
      isDestructive: true,
    );

    if (confirmed == true && widget.existingTransaction != null && mounted) {
      await ref.read(transactionRepositoryProvider).deleteTransaction(
            widget.existingTransaction!.id,
            widget.customerId,
          );

      await ref.read(customerLedgerViewModelProvider(widget.customerId).notifier).loadLedger();
      await ref.read(customerListViewModelProvider.notifier).loadCustomers();
      await ref.read(allTransactionsViewModelProvider.notifier).loadTransactions();

      if (mounted) {
        AppDialogs.showToast(context, 'Transaction deleted');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTransaction != null;
    final activeProfile = ref.watch(profileViewModelProvider).activeProfile;
    final currency = activeProfile?.currency ?? '\$';
    final settingsState = ref.watch(settingsViewModelProvider);
    final dateFormat = settingsState.settings.dateFormat;
    final timeFormat = settingsState.settings.timeFormat;

    final themeColor = _type == TransactionType.credit ? AppColors.creditRed : AppColors.paymentGreen;
    final pageTitle = isEdit
        ? 'Edit Transaction'
        : (_type == TransactionType.credit ? 'Give Credit' : 'Accept Payment');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(pageTitle),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _handleDelete,
              tooltip: 'Delete',
            ),
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            onPressed: _handleSave,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Transaction Type Selector (if adding or editing)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = TransactionType.credit),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.credit ? AppColors.creditRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Give Credit (Udhar)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _type == TransactionType.credit ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = TransactionType.payment),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.payment ? AppColors.paymentGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Accept Payment (Jama)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _type == TransactionType.payment ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currency,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: !isEdit,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Date Picker
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: themeColor, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(dateFormat).format(_selectedDateTime),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(height: 36, width: 1, color: AppColors.divider),
                  // Time Picker
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(Icons.access_time_rounded, color: themeColor, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(timeFormat).format(_selectedDateTime),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note / Remarks Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Note / Remarks (Optional)',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.edit_note_rounded, color: themeColor, size: 26),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleSave,
                child: Text(
                  isEdit ? 'SAVE CHANGES' : 'SAVE TRANSACTION',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
