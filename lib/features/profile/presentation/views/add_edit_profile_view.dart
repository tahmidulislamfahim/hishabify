import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../../../customer/presentation/views/customer_list_view.dart';
import '../../../settings/data/backup_restore_service.dart';
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
  bool _isRestoring = false;

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

  Future<void> _handleRestore() async {
    if (_isRestoring) return;

    final confirm = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Restore Backup',
      message:
          'Restoring a backup will import your saved stores, customers, and transactions. Proceed to select backup file?',
      confirmText: 'SELECT BACKUP FILE',
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);

    try {
      final status = await BackupRestoreService.restoreLocalBackup();
      if (!mounted) return;

      if (status == RestoreStatus.success) {
        await ref.read(settingsViewModelProvider.notifier).loadSettings();
        await ref.read(settingsViewModelProvider.notifier).setDisclosedTerms(true);
        await ref.read(profileViewModelProvider.notifier).loadProfiles();
        await ref.read(customerListViewModelProvider.notifier).loadCustomers();
        if (!mounted) return;

        final restoredProfiles = ref.read(profileViewModelProvider).profiles;
        if (restoredProfiles.isNotEmpty) {
          AppDialogs.showToast(context, 'Data restored successfully!');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CustomerListView()),
            (route) => false,
          );
          return;
        } else {
          AppDialogs.showToast(context, 'Backup restored, but no profiles found.');
        }
      } else if (status == RestoreStatus.invalidFile) {
        AppDialogs.showToast(context, 'Invalid backup file or corrupt data');
      } else if (status == RestoreStatus.error) {
        AppDialogs.showToast(context, 'Failed to import backup data');
      }
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showToast(context, 'Error restoring backup: $e');
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppDialogs.showToast(context, 'Please enter Profile Name');
      return;
    }

    final profileNotifier = ref.read(profileViewModelProvider.notifier);
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    final customerNotifier = ref.read(customerListViewModelProvider.notifier);

    final profile = Profile(
      id: widget.existingProfile?.id ?? const Uuid().v4(),
      name: name,
      type: _selectedType,
      currency: _selectedCurrency,
      isDefault: widget.existingProfile?.isDefault ?? true,
      createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
    );

    if (profile.isDefault || widget.existingProfile == null) {
      await settingsNotifier.setDefaultCurrency(_selectedCurrency);
    }
    await profileNotifier.saveProfile(profile);
    await customerNotifier.loadCustomers();

    if (!mounted) return;

    if (widget.isFirstTime) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerListView()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final profile = widget.existingProfile;
    if (profile == null) return;

    final profileNotifier = ref.read(profileViewModelProvider.notifier);
    final customerNotifier = ref.read(customerListViewModelProvider.notifier);
    final profileState = ref.read(profileViewModelProvider);
    final totalCount = profileState.profiles.length;
    final isActive = profileState.activeProfile?.id == profile.id;
    final entityType = profile.type == ProfileType.business ? 'store' : 'profile';
    final capitalizedType = profile.type == ProfileType.business ? 'Store' : 'Profile';

    if (totalCount <= 1) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Cannot Delete $capitalizedType'),
          content: Text(
            'At least one $entityType is required. To delete this $entityType, please create another $entityType first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Delete $capitalizedType',
      message: isActive
          ? 'Are you sure you want to delete "${profile.name}"?\n\nThis is currently your active $entityType. All transactions and customers in this $entityType will be permanently deleted.'
          : 'Are you sure you want to delete "${profile.name}"?\n\nAll transactions and customers associated with this $entityType will be permanently deleted.',
      confirmText: 'DELETE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await profileNotifier.deleteProfile(profile.id);
      await customerNotifier.loadCustomers();
      if (mounted) {
        AppDialogs.showToast(
          context,
          '$capitalizedType "${profile.name}" deleted successfully',
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final hasNoData = widget.existingProfile == null &&
        (widget.isFirstTime || profileState.profiles.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingProfile == null
            ? 'Profile Details'
            : (widget.existingProfile!.type == ProfileType.business ? 'Edit Store' : 'Edit Profile')),
        actions: [
          if (widget.existingProfile != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 24),
              onPressed: _isRestoring ? null : _handleDelete,
              tooltip: widget.existingProfile!.type == ProfileType.business ? 'Delete Store' : 'Delete Profile',
            ),
          if (hasNoData)
            IconButton(
              icon: const Icon(Icons.cloud_download_outlined, size: 24),
              onPressed: _isRestoring ? null : _handleRestore,
              tooltip: 'Restore Backup',
            ),
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            onPressed: _isRestoring ? null : _handleSave,
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
                onPressed: _isRestoring ? null : _handleSave,
                child: const Text('Save Profile'),
              ),
            ),
            if (hasNoData) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isRestoring ? null : _handleRestore,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isRestoring
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.cloud_download_rounded,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRestoring ? 'Restoring Data...' : 'Restore from Backup',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isRestoring
                                      ? 'Please wait while importing records...'
                                      : 'Already have a backup? Import your data here',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.existingProfile != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.creditRed),
                  label: Text(
                    widget.existingProfile!.type == ProfileType.business
                        ? 'Delete Store'
                        : 'Delete Profile',
                    style: const TextStyle(
                      color: AppColors.creditRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.creditRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
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
