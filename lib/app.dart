import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/security/app_lock_service.dart';
import 'core/security/app_lock_view.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/customer/presentation/views/customer_list_view.dart';
import 'features/onboarding/presentation/views/disclosure_view.dart';
import 'features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'features/profile/presentation/views/add_edit_profile_view.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';

class HishabifyApp extends ConsumerStatefulWidget {
  const HishabifyApp({super.key});

  @override
  ConsumerState<HishabifyApp> createState() => _HishabifyAppState();
}

class _HishabifyAppState extends ConsumerState<HishabifyApp> with WidgetsBindingObserver {
  bool _isUnlocked = false;
  bool _isLockChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final settings = ref.read(settingsViewModelProvider).settings;
      if (settings.appLockEnabled && !_isUnlocked) {
        _checkAppLock();
      }
    } else if (state == AppLifecycleState.paused) {
      final settings = ref.read(settingsViewModelProvider).settings;
      if (settings.appLockEnabled) {
        setState(() => _isUnlocked = false);
      }
    }
  }

  Future<void> _checkAppLock() async {
    final settings = ref.read(settingsViewModelProvider).settings;
    if (settings.appLockEnabled) {
      final result = await AppLockService.authenticateDetailed(
        reason: 'Please authenticate to access Hishabify',
      );
      if (result.isNoCredentials) {
        await ref.read(settingsViewModelProvider.notifier).setAppLock(false);
        if (mounted) {
          setState(() {
            _isUnlocked = true;
            _isLockChecked = true;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _isUnlocked = result.isSuccess;
          _isLockChecked = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isUnlocked = true;
          _isLockChecked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);

    return MaterialApp(
      title: 'Hishabify',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: _buildHome(settingsState, profileState),
    );
  }

  Widget _buildHome(SettingsState settingsState, ProfileState profileState) {
    if (settingsState.isLoading || profileState.isLoading || !_isLockChecked) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Hishabify',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (settingsState.settings.appLockEnabled && !_isUnlocked) {
      return AppLockView(onUnlockPressed: _checkAppLock);
    }

    if (!settingsState.settings.disclosedTerms) {
      return const DisclosureView();
    }

    if (profileState.profiles.isEmpty) {
      return const AddEditProfileView(isFirstTime: true);
    }

    return const CustomerListView();
  }
}
