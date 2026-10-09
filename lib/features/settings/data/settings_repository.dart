import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../domain/settings_model.dart';

class SettingsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<AppSettings> getSettings() async {
    final db = await _db.database;
    final maps = await db.query('settings');
    final map = {for (var item in maps) item['key'] as String: item['value'] as String};

    return AppSettings(
      appLockEnabled: map['app_lock_enabled'] == 'true',
      dateFormat: map['date_format'] ?? 'dd MMM yyyy',
      timeFormat: map['time_format'] ?? 'hh:mm a',
      defaultCurrency: map['default_currency'] ?? '\$',
      disclosedTerms: map['disclosed_terms'] == 'true',
    );
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await updateSetting('app_lock_enabled', settings.appLockEnabled ? 'true' : 'false');
    await updateSetting('date_format', settings.dateFormat);
    await updateSetting('time_format', settings.timeFormat);
    await updateSetting('default_currency', settings.defaultCurrency);
    await updateSetting('disclosed_terms', settings.disclosedTerms ? 'true' : 'false');
  }
}
