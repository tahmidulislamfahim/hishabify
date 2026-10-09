import 'package:sqflite/sqflite.dart';
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
    if (profile.isDefault) {
      // Clear previous default
      await db.update('profiles', {'is_default': 0});
    }
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
  }
}
