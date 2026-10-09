import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/security/app_lock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../data/backup_restore_service.dart';
import '../../domain/settings_model.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  static const List<String> _dateFormats = [
    'dd MMM yyyy',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];

  static const List<Map<String, String>> _timeFormats = [
    {'format': 'hh:mm a', 'label': '12 Hours (e.g. 02:30 PM)'},
    {'format': 'HH:mm', 'label': '24 Hours (e.g. 14:30)'},
  ];


  void _showDateFormatDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Date Format', style: TextStyle(fontWeight: FontWeight.bold)),
        contentPadding: const EdgeInsets.only(top: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _dateFormats.map((fmt) {
            return RadioListTile<String>(
              value: fmt,
              groupValue: current,
              title: Text(fmt),
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsViewModelProvider.notifier).setDateFormat(val);
                  Navigator.of(ctx).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTimeFormatDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Time Format', style: TextStyle(fontWeight: FontWeight.bold)),
        contentPadding: const EdgeInsets.only(top: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _timeFormats.map((tf) {
            final fmt = tf['format']!;
            final label = tf['label']!;
            return RadioListTile<String>(
              value: fmt,
              groupValue: current,
              title: Text(label),
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsViewModelProvider.notifier).setTimeFormat(val);
                  Navigator.of(ctx).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Default Currency', style: TextStyle(fontWeight: FontWeight.bold)),
        contentPadding: const EdgeInsets.only(top: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: AppSettings.availableCurrencies.map((c) {
              final sym = c['symbol']!;
              final name = c['name']!;
              return RadioListTile<String>(
                value: sym,
                groupValue: current,
                title: Text(name),
                activeColor: AppColors.primary,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsViewModelProvider.notifier).setDefaultCurrency(val);
                    Navigator.of(ctx).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAppLockToggle(BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final result = await AppLockService.authenticateDetailed(
        reason: 'Confirm your screen lock PIN, Pattern or Fingerprint to enable App Lock',
      );

      if (result.isSuccess) {
        await ref.read(settingsViewModelProvider.notifier).setAppLock(true);
        if (context.mounted) {
          AppDialogs.showToast(context, 'App Lock enabled');
        }
      } else if (result.isNoCredentials) {
        if (context.mounted) {
          _showNoCredentialsDialog(context);
        }
      } else {
        if (context.mounted) {
          AppDialogs.showToast(context, result.message ?? 'Authentication failed');
        }
      }
    } else {
      final result = await AppLockService.authenticateDetailed(
        reason: 'Confirm your screen lock PIN, Pattern or Fingerprint to disable App Lock',
      );

      if (result.isSuccess || result.isNoCredentials) {
        await ref.read(settingsViewModelProvider.notifier).setAppLock(false);
        if (context.mounted) {
          AppDialogs.showToast(context, 'App Lock disabled');
        }
      } else {
        if (context.mounted) {
          AppDialogs.showToast(context, result.message ?? 'Authentication failed');
        }
      }
    }
  }

  void _showNoCredentialsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('No Screen Lock Set', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Your device or emulator does not have a screen lock PIN, Pattern, Password, or Fingerprint configured.\n\nPlease set up a screen lock in your device\'s System Settings first before enabling System App Lock.',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      final file = await BackupRestoreService.exportLocalBackup();
      if (file != null && context.mounted) {
        AppDialogs.showToast(context, 'Backup saved and ready to share!');
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showToast(context, 'Backup failed: $e');
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final confirm = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Restore Backup',
      message: 'Restoring a backup will merge or overwrite current records. Proceed?',
      confirmText: 'RESTORE',
    );

    if (confirm == true) {
      final success = await BackupRestoreService.restoreLocalBackup();
      if (success && context.mounted) {
        await ref.read(profileViewModelProvider.notifier).loadProfiles();
        await ref.read(customerListViewModelProvider.notifier).loadCustomers();
        await ref.read(settingsViewModelProvider.notifier).loadSettings();
        if (context.mounted) {
          AppDialogs.showToast(context, 'Data restored successfully!');
        }
      } else if (context.mounted) {
        AppDialogs.showToast(context, 'Restore cancelled or invalid backup file');
      }
    }
  }

  Future<void> _handleClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Clear All Data',
      message: 'WARNING: This will permanently delete ALL profiles, customers, transactions and reports. This action cannot be undone!',
      confirmText: 'CLEAR EVERYTHING',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(settingsViewModelProvider.notifier).clearAllData();
      if (context.mounted) {
        AppDialogs.showToast(context, 'All data wiped successfully');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final settings = settingsState.settings;
    final currencyName = AppSettings.availableCurrencies.firstWhere(
      (c) => c['symbol'] == settings.defaultCurrency,
      orElse: () => {'name': settings.defaultCurrency, 'symbol': settings.defaultCurrency},
    )['name']!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Section: General Settings
          _buildSectionHeader('GENERAL'),
          _buildCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 26),
                title: const Text('System App Lock', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Require fingerprint or PIN to open the app', style: TextStyle(fontSize: 12)),
                activeThumbColor: AppColors.primary,
                value: settings.appLockEnabled,
                onChanged: (val) => _handleAppLockToggle(context, ref, val),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 24),
                title: const Text('Date Format', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(settings.dateFormat, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => _showDateFormatDialog(context, ref, settings.dateFormat),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 24),
                title: const Text('Time Format', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(settings.timeFormat == 'hh:mm a' ? '12 Hours (hh:mm a)' : '24 Hours (HH:mm)', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => _showTimeFormatDialog(context, ref, settings.timeFormat),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.attach_money_rounded, color: AppColors.primary, size: 24),
                title: const Text('Default Currency', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(currencyName, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => _showCurrencyDialog(context, ref, settings.defaultCurrency),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section: Backup & Restore
          _buildSectionHeader('BACKUP & RESTORE'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
                title: const Text('Take Local Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Export all data into a secure JSON backup file', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => _handleBackup(context),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined, color: AppColors.primary, size: 24),
                title: const Text('Restore Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Import previously exported backup file', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => _handleRestore(context, ref),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.creditRed, size: 24),
                title: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.creditRed)),
                subtitle: const Text('Permanently wipe all profiles and transactions', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => _handleClearAll(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section: About
          _buildSectionHeader('ABOUT'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.thumb_up_alt_outlined, color: AppColors.primary, size: 24),
                title: const Text('Rate The App', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => AppDialogs.showToast(context, 'Thank you for your 5-star rating!'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppColors.primary, size: 24),
                title: const Text('Share With Friends', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () => Share.share('Hishabify: Digital Udhar & Jama Ledger Book. 100% Free & Secure.'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}
