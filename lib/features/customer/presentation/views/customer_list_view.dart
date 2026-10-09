import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../core/utils/formatters.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../profile/presentation/views/manage_profiles_view.dart';
import '../../../reports/presentation/views/exported_reports_view.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../settings/presentation/views/settings_view.dart';
import '../../../transaction/presentation/views/all_transactions_view.dart';
import '../../../transaction/presentation/views/customer_ledger_view.dart';
import '../../data/customer_repository.dart';
import '../viewmodels/customer_list_viewmodel.dart';
import 'add_edit_customer_view.dart';

class CustomerListView extends ConsumerStatefulWidget {
  const CustomerListView({super.key});

  @override
  ConsumerState<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends ConsumerState<CustomerListView> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortDialog() {
    final currentSort = ref.read(customerListViewModelProvider).sortOption;

    showDialog(
      context: context,
      builder: (ctx) {
        CustomerSortOption selected = currentSort;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.only(top: 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: CustomerSortOption.values.map((opt) {
                  return RadioListTile<CustomerSortOption>(
                    value: opt,
                    groupValue: selected,
                    title: Text(opt.displayName),
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selected = val);
                        ref.read(customerListViewModelProvider.notifier).setSortOption(val);
                        Navigator.of(ctx).pop();
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCustomerSummaryDialog() {
    final customers = ref.read(customerListViewModelProvider).customers;
    final activeProfile = ref.read(profileViewModelProvider).activeProfile;
    final currency = activeProfile?.currency ?? '\$';

    double totalDue = 0.0;
    double totalAdvance = 0.0;
    int dueCount = 0;
    int advanceCount = 0;

    for (final c in customers) {
      if (c.netBalance > 0) {
        totalDue += c.netBalance;
        dueCount++;
      } else if (c.netBalance < 0) {
        totalAdvance += c.netBalance.abs();
        advanceCount++;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Customer Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.creditRedLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Due (You will get)', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$dueCount Customers', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Text(
                      AppFormatters.formatCurrency(totalDue, currency: currency),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.creditRed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paymentGreenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Advance (You will give)', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$advanceCount Customers', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Text(
                      AppFormatters.formatCurrency(totalAdvance, currency: currency),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.paymentGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Customers:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${customers.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerListViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);
    final settingsState = ref.watch(settingsViewModelProvider);

    final activeProfile = profileState.activeProfile;
    final currency = activeProfile?.currency ?? '\$';
    final dateFormat = settingsState.settings.dateFormat;
    final timeFormat = settingsState.settings.timeFormat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search customer name or phone...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  ref.read(customerListViewModelProvider.notifier).setSearchQuery(val);
                },
              )
            : const Text('Hishabify'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(customerListViewModelProvider.notifier).setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: _showSortDialog,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AllTransactionsView()),
              );
            },
            tooltip: 'All Transactions',
          ),
        ],
      ),
      drawer: _buildAppDrawer(context, activeProfile?.name ?? 'MyStore'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Profile Chip Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageProfilesView()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeProfile?.name ?? 'MyStore',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.chipText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.chipText),
                  ],
                ),
              ),
            ),
          ),

          // Customer List or Empty State
          Expanded(
            child: customerState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : customerState.customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_outline_rounded,
                                size: 44,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Customers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Please add your Customer',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => ref.read(customerListViewModelProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: customerState.customers.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final customer = customerState.customers[index];
                            final lastDate = customer.lastTransactionDate ?? customer.createdAt;
                            final formattedDate = AppFormatters.formatDateTime(
                              lastDate,
                              dateFormat: dateFormat,
                              timeFormat: timeFormat,
                            );

                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerLedgerView(customerId: customer.id),
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
                                            customer.phone != null && customer.phone!.isNotEmpty
                                                ? '${customer.name} - ${customer.phone}'
                                                : customer.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppFormatters.formatCurrency(customer.netBalance, currency: currency),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: customer.isDue
                                                ? AppColors.creditRed
                                                : (customer.isAdvance ? AppColors.paymentGreen : AppColors.textPrimary),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.balanceStatusText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: customer.isDue
                                                ? AppColors.creditRed
                                                : (customer.isAdvance ? AppColors.paymentGreen : AppColors.textMuted),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditCustomerView(),
            ),
          );
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, String profileName) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: AppColors.primary,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hishabify',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          profileName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Manage Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ManageProfilesView()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'All Transactions',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AllTransactionsView()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Customer Summary',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showCustomerSummaryDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.folder_shared_outlined,
                    title: 'Exported Reports',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExportedReportsView()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsView()),
                      );
                    },
                  ),
                  const Divider(color: AppColors.divider, height: 24),
                  _buildDrawerItem(
                    icon: Icons.thumb_up_alt_outlined,
                    title: 'Rate The App',
                    onTap: () {
                      Navigator.of(context).pop();
                      AppDialogs.showToast(context, 'Thank you for your 5-star support!');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.share_outlined,
                    title: 'Share With Friends',
                    onTap: () {
                      Navigator.of(context).pop();
                      Share.share(
                        'Manage all your Udhar & Jama ledgers digitally with Hishabify! 100% Free & Secure.',
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showInfoModal(
                        'Privacy Policy',
                        'Your data is stored 100% locally on your device. We do not track, collect or share your financial transactions with any third parties.',
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showInfoModal(
                        'Terms of Service',
                        'Hishabify is a free digital ledger tool designed to simplify credit and debit tracking for small businesses and personal bookkeeping.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  void _showInfoModal(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
