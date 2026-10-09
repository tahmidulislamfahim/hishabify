import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';

class BackupRestoreService {
  static Future<File?> exportLocalBackup() async {
    final data = await AppDatabase.instance.exportBackupJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(backupDir.path, 'Hishabify_Backup_$timestamp.json'));
    await file.writeAsString(jsonString);

    // Share / offer save to user
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hishabify Data Backup ($timestamp)',
    );

    return file;
  }

  static Future<bool> restoreLocalBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result.isEmpty || result.first.path == null) {
      return false;
    }

    final file = File(result.first.path!);
    final content = await file.readAsString();

    try {
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      if (decoded['app'] != 'Hishabify' && decoded['app'] != 'CreditLog' && !decoded.containsKey('customers')) {
        return false;
      }
      return await AppDatabase.instance.restoreFromBackupJson(decoded);
    } catch (_) {
      return false;
    }
  }
}
