import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hishabify/features/profile/presentation/views/add_edit_profile_view.dart';
import 'package:hishabify/features/profile/domain/profile_model.dart';
import 'package:hishabify/features/profile/data/profile_repository.dart';
import 'package:hishabify/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:hishabify/features/settings/data/settings_repository.dart';
import 'package:hishabify/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:hishabify/features/settings/domain/settings_model.dart';

class FakeProfileRepo extends ProfileRepository {
  final List<Profile> initialProfiles;
  FakeProfileRepo([this.initialProfiles = const []]);

  @override
  Future<List<Profile>> getAllProfiles() async => initialProfiles;

  @override
  Future<Profile?> getActiveProfile() async =>
      initialProfiles.isNotEmpty ? initialProfiles.first : null;
}

class FakeSettingsRepo extends SettingsRepository {
  @override
  Future<AppSettings> getSettings() async => AppSettings();
}

void main() {
  testWidgets('AddEditProfileView displays restore options when isFirstTime is true', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepo([])),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepo()),
        ],
        child: const MaterialApp(
          home: AddEditProfileView(isFirstTime: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 'Restore from Backup' text is present
    expect(find.text('Restore from Backup'), findsOneWidget);
    expect(find.text('Already have a backup? Import your data here'), findsOneWidget);

    // Verify the Restore tooltip in AppBar is present
    expect(find.byTooltip('Restore Backup'), findsOneWidget);

    // Verify Save Profile button is present
    expect(find.text('Save Profile'), findsOneWidget);
  });

  testWidgets('AddEditProfileView hides restore options when editing an existing profile', (tester) async {
    final existingProfile = Profile(
      id: 'store-1',
      name: 'Existing Store',
      type: ProfileType.business,
      currency: '\$',
      isDefault: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepo([existingProfile])),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepo()),
        ],
        child: MaterialApp(
          home: AddEditProfileView(existingProfile: existingProfile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 'Restore from Backup' is NOT shown
    expect(find.text('Restore from Backup'), findsNothing);
    expect(find.byTooltip('Restore Backup'), findsNothing);

    // Verify Edit Store title and Delete Store are shown
    expect(find.text('Edit Store'), findsOneWidget);
    expect(find.byTooltip('Delete Store'), findsOneWidget);
  });
}
