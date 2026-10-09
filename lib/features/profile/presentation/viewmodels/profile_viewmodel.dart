import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_model.dart';

class ProfileState {
  final Profile? activeProfile;
  final List<Profile> profiles;
  final bool isLoading;

  ProfileState({
    this.activeProfile,
    this.profiles = const [],
    this.isLoading = false,
  });

  ProfileState copyWith({
    Profile? activeProfile,
    List<Profile>? profiles,
    bool? isLoading,
  }) {
    return ProfileState(
      activeProfile: activeProfile ?? this.activeProfile,
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository _repo;

  ProfileViewModel(this._repo) : super(ProfileState()) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    state = state.copyWith(isLoading: true);
    final all = await _repo.getAllProfiles();
    final active = await _repo.getActiveProfile();
    state = state.copyWith(
      profiles: all,
      activeProfile: active,
      isLoading: false,
    );
  }

  Future<void> switchProfile(String profileId) async {
    await _repo.setActiveProfile(profileId);
    await loadProfiles();
  }

  Future<void> saveProfile(Profile profile) async {
    await _repo.saveProfile(profile);
    await loadProfiles();
  }

  Future<void> deleteProfile(String profileId) async {
    await _repo.deleteProfile(profileId);
    await loadProfiles();
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileViewModel(repo);
});
