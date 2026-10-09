import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../transaction/domain/transaction_model.dart';
import '../../domain/customer_model.dart';
import '../viewmodels/customer_list_viewmodel.dart';

class AddEditCustomerView extends ConsumerStatefulWidget {
  final Customer? existingCustomer;

  const AddEditCustomerView({
    super.key,
    this.existingCustomer,
  });

  @override
  ConsumerState<AddEditCustomerView> createState() => _AddEditCustomerViewState();
}

class _AddEditCustomerViewState extends ConsumerState<AddEditCustomerView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController();

  bool _hasCarryForward = false;
  TransactionType _carryForwardType = TransactionType.credit;

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      final c = widget.existingCustomer!;
      _nameController.text = c.name;
      _phoneController.text = c.phone ?? '';
      _emailController.text = c.email ?? '';
      _addressController.text = c.address ?? '';
      if (c.carryForwardBalance > 0) {
        _hasCarryForward = true;
        _balanceController.text = c.carryForwardBalance.toStringAsFixed(0);
        _carryForwardType = c.carryForwardType;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _importContact() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted) {
        if (mounted) {
          AppDialogs.showToast(context, 'Contact permission not granted');
        }
        return;
      }

      final contact = await FlutterContacts.native.showPicker();
      if (contact != null) {
        setState(() {
          _nameController.text = contact.displayName ?? '';
          if (contact.phones.isNotEmpty) {
            _phoneController.text = contact.phones.first.number.replaceAll(RegExp(r'\s+'), '');
          }
          if (contact.emails.isNotEmpty) {
            _emailController.text = contact.emails.first.address;
          }
          if (contact.addresses.isNotEmpty) {
            _addressController.text = contact.addresses.first.formatted ?? contact.addresses.first.street ?? '';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        AppDialogs.showToast(context, 'Unable to import contact');
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppDialogs.showToast(context, 'Please enter customer Name');
      return;
    }

    final activeProfile = ref.read(profileViewModelProvider).activeProfile;
    if (activeProfile == null) {
      AppDialogs.showToast(context, 'No active profile found');
      return;
    }

    final double carryBalance = _hasCarryForward
        ? (double.tryParse(_balanceController.text.trim()) ?? 0.0)
        : 0.0;

    final customer = Customer(
      id: widget.existingCustomer?.id ?? const Uuid().v4(),
      profileId: activeProfile.id,
      name: name,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      carryForwardBalance: carryBalance,
      carryForwardType: _carryForwardType,
      createdAt: widget.existingCustomer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.existingCustomer == null) {
      await ref.read(customerRepositoryProvider).saveCustomer(customer, isNew: true);
    } else {
      await ref.read(customerRepositoryProvider).updateCustomer(customer);
    }

    await ref.read(customerListViewModelProvider.notifier).loadCustomers();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCustomer != null;
    final activeProfile = ref.watch(profileViewModelProvider).activeProfile;
    final currency = activeProfile?.currency ?? '\$';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Customer Detail' : 'Add Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_rounded),
            onPressed: _importContact,
            tooltip: 'Import from Contacts',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Mobile No (Optional)',
                      prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email Id (Optional)',
                      prefixIcon: Icon(Icons.email, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Address (Optional)',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Carry forward balance section (available when adding customer)
            if (!isEdit)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Existing customer, add carry forward balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch(
                          value: _hasCarryForward,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _hasCarryForward = val);
                          },
                        ),
                      ],
                    ),
                    if (_hasCarryForward) ...[
                      const Divider(color: AppColors.divider, height: 24),
                      TextField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Carry Forward Balance',
                          prefixText: '$currency ',
                          prefixStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _carryForwardType = TransactionType.credit),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _carryForwardType == TransactionType.credit
                                      ? AppColors.creditRedLight
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _carryForwardType == TransactionType.credit
                                        ? AppColors.creditRed
                                        : AppColors.border,
                                    width: _carryForwardType == TransactionType.credit ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Credit (Udhar)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _carryForwardType == TransactionType.credit
                                          ? AppColors.creditRed
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _carryForwardType = TransactionType.payment),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _carryForwardType == TransactionType.payment
                                      ? AppColors.paymentGreenLight
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _carryForwardType == TransactionType.payment
                                        ? AppColors.paymentGreen
                                        : AppColors.border,
                                    width: _carryForwardType == TransactionType.payment ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Advance (Payment)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _carryForwardType == TransactionType.payment
                                          ? AppColors.paymentGreen
                                          : AppColors.textSecondary,
                                    ),
                                  ),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: Text(isEdit ? 'Save Changes' : 'Save Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
