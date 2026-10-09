import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/customer_model.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/filter_model.dart';

class TransactionFilterView extends ConsumerStatefulWidget {
  final TransactionFilter currentFilter;

  const TransactionFilterView({
    super.key,
    required this.currentFilter,
  });

  @override
  ConsumerState<TransactionFilterView> createState() => _TransactionFilterViewState();
}

class _TransactionFilterViewState extends ConsumerState<TransactionFilterView> {
  late DateFilterMode _dateMode;
  late QuickDateOption _quickDate;
  late DateTime _startDate;
  late DateTime _endDate;
  late FilterTypeOption _typeFilter;
  String? _selectedCustomerId;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _dateMode = widget.currentFilter.dateMode;
    _quickDate = widget.currentFilter.quickDate;
    _startDate = widget.currentFilter.customStartDate ?? DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.currentFilter.customEndDate ?? DateTime.now();
    _typeFilter = widget.currentFilter.typeFilter;
    _selectedCustomerId = widget.currentFilter.selectedCustomerId;

    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final activeProfile = ref.read(profileViewModelProvider).activeProfile;
    if (activeProfile != null) {
      final custs = await ref.read(customerRepositoryProvider).getCustomers(profileId: activeProfile.id);
      if (mounted) {
        setState(() {
          _customers = custs;
        });
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline, color: AppColors.primary),
                title: const Text('All Customers', style: TextStyle(fontWeight: FontWeight.bold)),
                selected: _selectedCustomerId == null,
                onTap: () {
                  setState(() => _selectedCustomerId = null);
                  Navigator.of(ctx).pop();
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final c = _customers[index];
                    final isSel = _selectedCustomerId == c.id;
                    return ListTile(
                      title: Text(c.name, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      subtitle: c.phone != null ? Text(c.phone!) : null,
                      selected: isSel,
                      trailing: isSel ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() => _selectedCustomerId = c.id);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _reset() {
    setState(() {
      _dateMode = DateFilterMode.quickAccess;
      _quickDate = QuickDateOption.all;
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _typeFilter = FilterTypeOption.all;
      _selectedCustomerId = null;
    });
  }

  void _apply() {
    final newFilter = TransactionFilter(
      dateMode: _dateMode,
      quickDate: _quickDate,
      customStartDate: _startDate,
      customEndDate: _endDate,
      typeFilter: _typeFilter,
      selectedCustomerId: _selectedCustomerId,
    );
    Navigator.of(context).pop(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider).settings;
    final dateFormat = settings.dateFormat;

    String selectedCustomerName = 'All Customers';
    if (_selectedCustomerId != null) {
      final found = _customers.where((c) => c.id == _selectedCustomerId);
      if (found.isNotEmpty) selectedCustomerName = found.first.name;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Transactions'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('RESET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATE FILTER',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<DateFilterMode>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Quick Access', style: TextStyle(fontWeight: FontWeight.w600)),
                          value: DateFilterMode.quickAccess,
                          groupValue: _dateMode,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            if (val != null) setState(() => _dateMode = val);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<DateFilterMode>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Between Dates', style: TextStyle(fontWeight: FontWeight.w600)),
                          value: DateFilterMode.betweenTwoDates,
                          groupValue: _dateMode,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            if (val != null) setState(() => _dateMode = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 16),
                  if (_dateMode == DateFilterMode.quickAccess) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: QuickDateOption.values.map((opt) {
                        final isSel = _quickDate == opt;
                        return ChoiceChip(
                          label: Text(opt.displayName),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _quickDate = opt);
                          },
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('From', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(dateFormat).format(_startDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('To', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(dateFormat).format(_endDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

            // Transaction Type Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRANSACTION TYPE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: FilterTypeOption.values.map((opt) {
                      final isSel = _typeFilter == opt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(child: Text(opt.displayName)),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _typeFilter = opt);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CUSTOMER',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _customers.isEmpty ? null : _showCustomerPicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedCustomerId == null ? Icons.people_outline : Icons.person_outline,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedCustomerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _apply,
                child: const Text(
                  'APPLY FILTER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
