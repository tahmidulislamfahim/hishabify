import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../../domain/profile_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'add_edit_profile_view.dart';

class ManageProfilesView extends ConsumerWidget {
  const ManageProfilesView({super.key});

  Future<void> _handleDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    bool isActive,
    int totalCount,
  ) async {
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

    if (confirmed == true && context.mounted) {
      final profileNotifier = ref.read(profileViewModelProvider.notifier);
      final customerNotifier = ref.read(customerListViewModelProvider.notifier);
      await profileNotifier.deleteProfile(profile.id);
      await customerNotifier.loadCustomers();
      if (context.mounted) {
        AppDialogs.showToast(
          context,
          '$capitalizedType "${profile.name}" deleted successfully',
        );
      }
    }
  }

  void _showProfileOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    bool isActive,
    int totalCount,
  ) {
    final entityType = profile.type == ProfileType.business ? 'Store' : 'Profile';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (!isActive)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                  title: Text('Set as Active $entityType'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final profileNotifier = ref.read(profileViewModelProvider.notifier);
                    final customerNotifier = ref.read(customerListViewModelProvider.notifier);
                    await profileNotifier.switchProfile(profile.id);
                    await customerNotifier.loadCustomers();
                    if (context.mounted) {
                      AppDialogs.showToast(context, 'Switched to ${profile.name}');
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                title: Text('Edit $entityType'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditProfileView(existingProfile: profile),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.creditRed),
                title: Text('Delete $entityType', style: const TextStyle(color: AppColors.creditRed)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleDeleteProfile(context, ref, profile, isActive, totalCount);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
    final profiles = profileState.profiles;
    final activeProfile = profileState.activeProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Profile'),
      ),
      body: profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No User found', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const Text('Please add your Users', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: profiles.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final isActive = activeProfile?.id == profile.id;
                final entityType = profile.type == ProfileType.business ? 'Store' : 'Profile';

                return InkWell(
                  onTap: () async {
                    if (!isActive) {
                      final profileNotifier = ref.read(profileViewModelProvider.notifier);
                      final customerNotifier = ref.read(customerListViewModelProvider.notifier);
                      await profileNotifier.switchProfile(profile.id);
                      await customerNotifier.loadCustomers();
                      if (context.mounted) {
                        AppDialogs.showToast(context, 'Switched to ${profile.name}');
                      }
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditProfileView(existingProfile: profile),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    _showProfileOptionsSheet(context, ref, profile, isActive, profiles.length);
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.creditRedLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            profile.type == ProfileType.business
                                ? Icons.storefront_rounded
                                : Icons.person,
                            color: AppColors.creditRed,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${profile.type.displayName} (${profile.currency})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                          tooltip: '$entityType options',
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEditProfileView(existingProfile: profile),
                                ),
                              );
                            } else if (value == 'delete') {
                              _handleDeleteProfile(
                                context,
                                ref,
                                profile,
                                isActive,
                                profiles.length,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
                                  const SizedBox(width: 12),
                                  Text('Edit $entityType'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, size: 20, color: AppColors.creditRed),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete $entityType',
                                    style: const TextStyle(color: AppColors.creditRed),
                                  ),
                                ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditProfileView(),
            ),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
