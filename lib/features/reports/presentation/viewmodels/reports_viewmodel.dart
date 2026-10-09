import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../data/reports_repository.dart';
import '../../domain/report_file_model.dart';

class ReportsState {
  final List<ReportFileItem> reports;
  final bool isAscending;
  final bool isLoading;

  ReportsState({
    this.reports = const [],
    this.isAscending = false,
    this.isLoading = false,
  });

  ReportsState copyWith({
    List<ReportFileItem>? reports,
    bool? isAscending,
    bool? isLoading,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      isAscending: isAscending ?? this.isAscending,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

class ReportsViewModel extends StateNotifier<ReportsState> {
  final ReportsRepository _repo;

  ReportsViewModel(this._repo) : super(ReportsState()) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true);
    final reports = await _repo.getAllReports(ascending: state.isAscending);
    state = state.copyWith(reports: reports, isLoading: false);
  }

  void toggleSort() {
    state = state.copyWith(isAscending: !state.isAscending);
    loadReports();
  }

  Future<void> deleteReport(String reportId, String filePath) async {
    await _repo.deleteReport(reportId, filePath);
    await loadReports();
  }

  Future<void> openReport(ReportFileItem report) async {
    final file = File(report.filePath);
    if (!await file.exists()) return;

    if (report.fileType == 'pdf') {
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: report.fileName,
      );
    } else {
      // Share/open excel
      await Share.shareXFiles([XFile(report.filePath)]);
    }
  }

  Future<void> shareReport(ReportFileItem report) async {
    final file = File(report.filePath);
    if (!await file.exists()) return;
    await Share.shareXFiles([XFile(report.filePath)], text: report.fileName);
  }
}

final reportsViewModelProvider = StateNotifierProvider<ReportsViewModel, ReportsState>((ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  return ReportsViewModel(repo);
});
