import 'package:flutter_test/flutter_test.dart';
import 'package:hishabify/features/profile/domain/profile_model.dart';

void main() {
  group('Profile Model Tests', () {
    test('Profile serialization and copyWith works correctly', () {
      final now = DateTime.now();
      final profile = Profile(
        id: 'p1',
        name: 'MyStore',
        type: ProfileType.business,
        currency: '\$',
        isDefault: true,
        createdAt: now,
      );

      final map = profile.toMap();
      expect(map['id'], 'p1');
      expect(map['name'], 'MyStore');
      expect(map['type'], 'business');
      expect(map['is_default'], 1);

      final fromMap = Profile.fromMap(map);
      expect(fromMap.id, profile.id);
      expect(fromMap.name, profile.name);
      expect(fromMap.type, ProfileType.business);
      expect(fromMap.isDefault, true);

      final updated = profile.copyWith(name: 'Updated Store', isDefault: false);
      expect(updated.name, 'Updated Store');
      expect(updated.isDefault, false);
      expect(updated.id, 'p1');
    });

    test('ProfileType parser and displayName', () {
      expect(ProfileType.fromString('business'), ProfileType.business);
      expect(ProfileType.fromString('personal'), ProfileType.personal);
      expect(ProfileType.business.displayName, 'Business');
      expect(ProfileType.personal.displayName, 'Personal');
    });
  });
}
