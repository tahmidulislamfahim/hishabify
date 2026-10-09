import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../../../customer/presentation/views/customer_list_view.dart';
import '../../../settings/domain/settings_model.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/profile_model.dart';
import '../viewmodels/profile_viewmodel.dart';

class AddEditProfileView extends ConsumerStatefulWidget {
  final Profile? existingProfile;
  final bool isFirstTime;

  const AddEditProfileView({
    super.key,
    this.existingProfile,
    this.isFirstTime = false,
  });

  @override
  ConsumerState<AddEditProfileView> createState() => _AddEditProfileViewState();
}

class _AddEditProfileViewState extends ConsumerState<AddEditProfileView> {
  final _nameController = TextEditingController();
  ProfileType _selectedType = ProfileType.business;
  String _selectedCurrency = '\$';

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _nameController.text = widget.existingProfile!.name;
      _selectedType = widget.existingProfile!.type;
      _selectedCurrency = widget.existingProfile!.currency;
    } else {
      _nameController.text = 'MyStore';
      _selectedCurrency = ref.read(settingsViewModelProvider).settings.defaultCurrency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppDialogs.showToast(context, 'Please enter Profile Name');
      return;
    }

    final profile = Profile(
      id: widget.existingProfile?.id ?? const Uuid().v4(),
      name: name,
      type: _selectedType,
      currency: _selectedCurrency,
      isDefault: widget.existingProfile?.isDefault ?? true,
      createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
    );

    await ref.read(profileViewModelProvider.notifier).saveProfile(profile);
    if (profile.isDefault || widget.existingProfile == null) {
      await ref.read(settingsViewModelProvider.notifier).setDefaultCurrency(_selectedCurrency);
    }
    await ref.read(customerListViewModelProvider.notifier).loadCustomers();

    if (!mounted) return;

    if (widget.isFirstTime) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerListView()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingProfile == null ? 'Profile Details' : 'Edit Profile'),
        actions: [
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Account Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    type: ProfileType.business,
                    title: 'Business',
                    subtitle: 'For shops, stores & vendors',
                    icon: Icons.storefront_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTypeCard(
                    type: ProfileType.personal,
                    title: 'Personal',
                    subtitle: 'For daily personal expenses',
                    icon: Icons.person_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Business / Personal name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter name (e.g. MyStore)',
                prefixIcon: Icon(
                  _selectedType == ProfileType.business ? Icons.business : Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Set Your Currency',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items: AppSettings.availableCurrencies.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['symbol'],
                      child: Text(
                        '${c['name']}',
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCurrency = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required ProfileType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
