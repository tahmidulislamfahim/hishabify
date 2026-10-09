import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'add_edit_profile_view.dart';

class ManageProfilesView extends ConsumerWidget {
  const ManageProfilesView({super.key});

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

                return InkWell(
                  onTap: () async {
                    if (!isActive) {
                      await ref.read(profileViewModelProvider.notifier).switchProfile(profile.id);
                      await ref.read(customerListViewModelProvider.notifier).loadCustomers();
                      if (context.mounted) {
                        AppDialogs.showToast(context, 'Switched to ${profile.name}');
                      }
                    }
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
                          child: const Icon(
                            Icons.person,
                            color: AppColors.creditRed,
                            size: 28,
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
                                profile.type.displayName,
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
