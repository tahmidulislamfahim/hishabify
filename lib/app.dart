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
  bool _isAuthenticating = false;
  bool _hasInitialAuthTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticating) return;

    final settings = ref.read(settingsViewModelProvider).settings;
    if (!settings.appLockEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (mounted) {
        setState(() {
          _isUnlocked = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isUnlocked) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final settings = ref.read(settingsViewModelProvider).settings;
      if (!settings.appLockEnabled) {
        if (mounted) {
          setState(() {
            _isUnlocked = true;
          });
        }
        return;
      }

      final result = await AppLockService.authenticateDetailed(
        reason: 'Please authenticate to access Hishabify',
      );

      if (result.isNoCredentials) {
        await ref.read(settingsViewModelProvider.notifier).setAppLock(false);
        if (mounted) {
          setState(() {
            _isUnlocked = true;
          });
        }
      } else if (mounted) {
        setState(() {
          _isUnlocked = result.isSuccess;
        });
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);

    // If settings finished loading and app lock is NOT enabled, keep unlocked
    if (!settingsState.isLoading && !settingsState.settings.appLockEnabled && !_isUnlocked) {
      _isUnlocked = true;
    }

    // On cold start, if settings finished loading and app lock IS enabled, auto-trigger authentication once
    if (!settingsState.isLoading && settingsState.settings.appLockEnabled && !_hasInitialAuthTriggered) {
      _hasInitialAuthTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isUnlocked) {
          _authenticate();
        }
      });
    }

    final isLocked = !settingsState.isLoading && settingsState.settings.appLockEnabled && !_isUnlocked;

    return MaterialApp(
      title: 'Hishabify',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: _buildHome(settingsState, profileState),
      builder: (context, child) {
        if (isLocked) {
          return PopScope(
            canPop: false,
            child: AppLockView(onUnlockPressed: _authenticate),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildHome(SettingsState settingsState, ProfileState profileState) {
    if (settingsState.isLoading || profileState.isLoading) {
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

    if (!settingsState.settings.disclosedTerms) {
      return const DisclosureView();
    }

    if (profileState.profiles.isEmpty) {
      return const AddEditProfileView(isFirstTime: true);
    }

    return const CustomerListView();
  }
}
