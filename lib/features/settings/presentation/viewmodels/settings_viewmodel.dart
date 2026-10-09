import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/database/app_database.dart';
import '../../data/settings_repository.dart';
import '../../domain/settings_model.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../customer/presentation/viewmodels/customer_list_viewmodel.dart';

class SettingsState {
  final AppSettings settings;
  final bool isLoading;

  SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsViewModel extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;
  final Ref _ref;

  SettingsViewModel(this._repo, this._ref) : super(SettingsState()) {
    loadSettings();
    _ref.listen<ProfileState>(profileViewModelProvider, (previous, next) {
      final newCurrency = next.activeProfile?.currency;
      if (newCurrency != null && state.settings.defaultCurrency != newCurrency) {
        setDefaultCurrency(newCurrency, updateProfile: false);
      }
    });
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    var settings = await _repo.getSettings();
    final activeProfile = await _ref.read(profileRepositoryProvider).getActiveProfile();
    if (activeProfile != null && settings.defaultCurrency != activeProfile.currency) {
      settings = settings.copyWith(defaultCurrency: activeProfile.currency);
      await _repo.saveSettings(settings);
    }
    state = state.copyWith(settings: settings, isLoading: false);
  }

  Future<void> setAppLock(bool enabled) async {
    final updated = state.settings.copyWith(appLockEnabled: enabled);
    state = state.copyWith(settings: updated);
    await _repo.saveSettings(updated);
  }

  Future<void> setDateFormat(String format) async {
    final updated = state.settings.copyWith(dateFormat: format);
    state = state.copyWith(settings: updated);
    await _repo.saveSettings(updated);
  }

  Future<void> setTimeFormat(String format) async {
    final updated = state.settings.copyWith(timeFormat: format);
    state = state.copyWith(settings: updated);
    await _repo.saveSettings(updated);
  }

  Future<void> setDefaultCurrency(String currency, {bool updateProfile = true}) async {
    if (state.settings.defaultCurrency == currency && !updateProfile) return;
    final updated = state.settings.copyWith(defaultCurrency: currency);
    state = state.copyWith(settings: updated);
    await _repo.saveSettings(updated);

    if (updateProfile) {
      final profileNotifier = _ref.read(profileViewModelProvider.notifier);
      final activeProfile = _ref.read(profileViewModelProvider).activeProfile;
      if (activeProfile != null && activeProfile.currency != currency) {
        final updatedProfile = activeProfile.copyWith(currency: currency);
        await profileNotifier.saveProfile(updatedProfile);
      }
    }
  }

  Future<void> setDisclosedTerms(bool disclosed) async {
    final updated = state.settings.copyWith(disclosedTerms: disclosed);
    state = state.copyWith(settings: updated);
    await _repo.saveSettings(updated);
  }

  Future<void> clearAllData() async {
    await AppDatabase.instance.clearAllData();
    await loadSettings();
    await _ref.read(profileViewModelProvider.notifier).loadProfiles();
    await _ref.read(customerListViewModelProvider.notifier).loadCustomers();
  }
}

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsViewModel(repo, ref);
});
