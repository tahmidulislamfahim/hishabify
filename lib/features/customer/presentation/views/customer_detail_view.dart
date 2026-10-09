import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../core/utils/formatters.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/customer_model.dart';
import '../viewmodels/customer_list_viewmodel.dart';
import 'add_edit_customer_view.dart';

class CustomerDetailView extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailView({
    super.key,
    required this.customer,
  });

  @override
  ConsumerState<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends ConsumerState<CustomerDetailView> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _refreshCustomer() async {
    final updated = await ref.read(customerRepositoryProvider).getCustomerById(_customer.id);
    if (updated != null && mounted) {
      setState(() {
        _customer = updated;
      });
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppDialogs.showToast(context, 'Cannot open phone dialer');
    }
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppDialogs.showToast(context, 'Cannot open SMS app');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppDialogs.showToast(context, 'Cannot open email app');
    }
  }

  Future<void> _handleDeleteCustomer() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Settle and Delete Customer',
      message:
          'Are you sure you want to delete ${_customer.name}? All transaction history for this customer will be permanently deleted.',
      confirmText: 'DELETE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(customerRepositoryProvider).settleAndDeleteCustomer(_customer.id);
      await ref.read(customerListViewModelProvider.notifier).loadCustomers();
      if (mounted) {
        AppDialogs.showToast(context, 'Customer deleted successfully');
        // Pop back twice to return to customer list
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);
    final currency = profileState.activeProfile?.currency ?? '\$';
    final dateFormat = settingsState.settings.dateFormat;
    final timeFormat = settingsState.settings.timeFormat;

    final initial = _customer.name.isNotEmpty ? _customer.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditCustomerView(existingCustomer: _customer),
                ),
              );
              await _refreshCustomer();
            },
            tooltip: 'Edit Customer',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _handleDeleteCustomer,
            tooltip: 'Delete Customer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Name Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _customer.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_customer.phone != null && _customer.phone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _customer.phone!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Current Balance Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _customer.isDue
                          ? AppColors.creditRedLight
                          : (_customer.isAdvance ? AppColors.paymentGreenLight : AppColors.cardBackground),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${AppFormatters.formatCurrency(_customer.netBalance, currency: currency)} (${_customer.balanceStatusText})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _customer.isDue
                            ? AppColors.creditRed
                            : (_customer.isAdvance ? AppColors.paymentGreen : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact Actions (if phone present)
            if (_customer.phone != null && _customer.phone!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      color: AppColors.primary,
                      onTap: () => _callPhone(_customer.phone!),
                    ),
                    Container(height: 32, width: 1, color: AppColors.divider),
                    _buildActionButton(
                      icon: Icons.message_rounded,
                      label: 'SMS',
                      color: AppColors.paymentGreen,
                      onTap: () => _sendSms(_customer.phone!),
                    ),
                  ],
                ),
              ),
            if (_customer.phone != null && _customer.phone!.isNotEmpty) const SizedBox(height: 16),

            // Customer Details List Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (_customer.email != null && _customer.email!.isNotEmpty) ...[
                    _buildDetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _customer.email!,
                      onTapValue: () => _sendEmail(_customer.email!),
                    ),
                    const Divider(color: AppColors.divider, height: 24),
                  ],
                  if (_customer.address != null && _customer.address!.isNotEmpty) ...[
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: _customer.address!,
                    ),
                    const Divider(color: AppColors.divider, height: 24),
                  ],
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Added On',
                    value: AppFormatters.formatDateTime(
                      _customer.createdAt,
                      dateFormat: dateFormat,
                      timeFormat: timeFormat,
                    ),
                  ),
                  if (_customer.carryForwardBalance > 0) ...[
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow(
                      icon: Icons.history_rounded,
                      label: 'Carry Forward Balance',
                      value:
                          '${AppFormatters.formatCurrency(_customer.carryForwardBalance, currency: currency)} (${_customer.carryForwardType.name.toUpperCase()})',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settle and Delete Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.creditRed,
                  side: const BorderSide(color: AppColors.creditRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.delete_forever_rounded, color: AppColors.creditRed),
                label: const Text(
                  'Settle and Delete Customer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _handleDeleteCustomer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTapValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              InkWell(
                onTap: onTapValue,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: onTapValue != null ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
