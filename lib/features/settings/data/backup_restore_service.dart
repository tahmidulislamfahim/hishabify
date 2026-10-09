import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';

enum RestoreStatus {
  success,
  cancelled,
  invalidFile,
  error,
}

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

  static Future<RestoreStatus> restoreLocalBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result.isEmpty || result.first.path == null) {
      return RestoreStatus.cancelled;
    }

    try {
      final file = File(result.first.path!);
      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        return RestoreStatus.invalidFile;
      }

      if (decoded['app'] != 'Hishabify' &&
          decoded['app'] != 'CreditLog' &&
          !decoded.containsKey('customers') &&
          !decoded.containsKey('profiles')) {
        return RestoreStatus.invalidFile;
      }

      final success = await AppDatabase.instance.restoreFromBackupJson(decoded);
      return success ? RestoreStatus.success : RestoreStatus.error;
    } catch (e, stack) {
      debugPrint('Restore error in BackupRestoreService: $e\n$stack');
      return RestoreStatus.invalidFile;
    }
  }
}
