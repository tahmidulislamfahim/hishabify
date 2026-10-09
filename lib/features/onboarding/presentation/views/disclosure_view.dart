import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../profile/presentation/views/add_edit_profile_view.dart';

class DisclosureView extends ConsumerWidget {
  const DisclosureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hishabify'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Terms & Privacy Policy',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This app is governed by Terms of Service. By continuing to use this app you represent that you have read and accept the Terms of Service, Privacy Policy and Permission disclosure.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('TERMS OF SERVICE'),
                      const Text(
                        '1. Digital Ledger & Account Book: This app assists you in tracking personal and business credits (Udhar) and payments (Jama).\n'
                        '2. Data Ownership: All your financial ledger entries and customer details are stored securely on your local device.\n'
                        '3. Ad-Free & Subscription-Free: Enjoy a 100% ad-free experience with all pro features unlocked without subscriptions.',
                        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('PRIVACY POLICY'),
                      const Text(
                        'Your financial privacy is sacred. We do not transmit or sell your ledger records to external tracking or advertising networks. Your data remains on your device and inside your own personal backups.',
                        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('PERMISSIONS REQUIRED'),
                      const Text(
                        '• Contacts: Optional access to easily import customer names and phone numbers from your address book.\n'
                        '• Storage / Media: Used exclusively for exporting and saving your PDF statements and Excel reports.\n'
                        '• Biometrics / Screen Lock: Used to secure your ledger with System App Lock.',
                        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await ref.read(settingsViewModelProvider.notifier).setDisclosedTerms(true);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AddEditProfileView(isFirstTime: true),
                      ),
                    );
                  }
                },
                child: const Text(
                  'ACCEPT AND CONTINUE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
