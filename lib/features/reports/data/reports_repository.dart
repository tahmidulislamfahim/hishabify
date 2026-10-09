import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../domain/report_file_model.dart';

class ReportsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<ReportFileItem>> getAllReports({bool ascending = false}) async {
    final db = await _db.database;
    final order = ascending ? 'ASC' : 'DESC';
    final maps = await db.query('exported_reports', orderBy: 'created_at $order');
    return maps.map((m) => ReportFileItem.fromMap(m)).toList();
  }

  Future<void> saveReport(ReportFileItem report) async {
    final db = await _db.database;
    await db.insert(
      'exported_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteReport(String reportId, String filePath) async {
    final db = await _db.database;
    await db.delete('exported_reports', where: 'id = ?', whereArgs: [reportId]);

    // Also delete physical file if exists
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
