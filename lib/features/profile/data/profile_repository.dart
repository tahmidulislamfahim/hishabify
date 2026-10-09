import '../../../core/database/app_database.dart';
import '../domain/profile_model.dart';

class ProfileRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Profile>> getAllProfiles() async {
    final db = await _db.database;
    final maps = await db.query('profiles', orderBy: 'created_at ASC');
    return maps.map((m) => Profile.fromMap(m)).toList();
  }

  Future<Profile?> getActiveProfile() async {
    final db = await _db.database;
    final maps = await db.query(
      'profiles',
      where: 'is_default = 1',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Profile.fromMap(maps.first);
    }
    // If none marked default, get first
    final all = await getAllProfiles();
    return all.isNotEmpty ? all.first : null;
  }

  Future<void> saveProfile(Profile profile) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      if (profile.isDefault) {
        // Clear previous default
        await txn.update('profiles', {'is_default': 0});
      }

      final existing = await txn.query(
        'profiles',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [profile.id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Use UPDATE so we never trigger SQLite's ON DELETE CASCADE on customers/transactions
        await txn.update(
          'profiles',
          profile.toMap(),
          where: 'id = ?',
          whereArgs: [profile.id],
        );
      } else {
        await txn.insert('profiles', profile.toMap());
      }
    });
  }

  Future<void> setActiveProfile(String profileId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('profiles', {'is_default': 0});
      await txn.update(
        'profiles',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [profileId],
      );
    });
  }

  Future<void> deleteProfile(String profileId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('customers', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('profiles', where: 'id = ?', whereArgs: [profileId]);

      final remaining = await txn.query('profiles', orderBy: 'created_at ASC');
      final hasDefault = remaining.any((m) => (m['is_default'] as int? ?? 0) == 1);
      if (remaining.isNotEmpty && !hasDefault) {
        final newDefaultId = remaining.first['id'] as String;
        await txn.update(
          'profiles',
          {'is_default': 1},
          where: 'id = ?',
          whereArgs: [newDefaultId],
        );
      }
    });
  }
}
