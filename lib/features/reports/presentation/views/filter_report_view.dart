import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../customer/domain/customer_model.dart';
import '../../../filter/domain/filter_model.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../transaction/presentation/viewmodels/customer_ledger_viewmodel.dart';
import '../../domain/report_file_model.dart';
import '../../presentation/viewmodels/reports_viewmodel.dart';
import '../../services/excel_report_service.dart';
import '../../services/pdf_report_service.dart';
import 'exported_reports_view.dart';

class FilterReportView extends ConsumerStatefulWidget {
  final Customer customer;

  const FilterReportView({
    super.key,
    required this.customer,
  });

  @override
  ConsumerState<FilterReportView> createState() => _FilterReportViewState();
}

class _FilterReportViewState extends ConsumerState<FilterReportView> {
  DateFilterMode _dateMode = DateFilterMode.quickAccess;
  QuickDateOption _quickOption = QuickDateOption.all;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _includeNotes = true;
  String _format = 'pdf'; // 'pdf' or 'excel'
  bool _isExporting = false;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<ReportFileItem?> _generateReport() async {
    final activeProfile = ref.read(profileViewModelProvider).activeProfile;
    if (activeProfile == null) {
      AppDialogs.showToast(context, 'No active profile found');
      return null;
    }

    final settings = ref.read(settingsViewModelProvider).settings;

    // Build filter to query transactions
    final filter = TransactionFilter(
      dateMode: _dateMode,
      quickDate: _quickOption,
      customStartDate: _startDate,
      customEndDate: _endDate,
      typeFilter: FilterTypeOption.all,
      selectedCustomerId: widget.customer.id,
    );

    final txRepo = ref.read(transactionRepositoryProvider);
    final allCustomerTxs = await txRepo.getCustomerTransactions(widget.customer.id);

    // Apply date filtering
    final dateRange = filter.effectiveDateRange;
    final filteredTxs = allCustomerTxs.where((tx) {
      if (dateRange == null) return true;
      return tx.dateTime.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
          tx.dateTime.isBefore(dateRange.end.add(const Duration(seconds: 1)));
    }).toList();

    // Sort ascending for chronological ledger
    filteredTxs.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    ReportFileItem reportItem;
    if (_format == 'pdf') {
      reportItem = await PdfReportService.generateCustomerStatement(
        profile: activeProfile,
        customer: widget.customer,
        transactions: filteredTxs,
        includeNotes: _includeNotes,
        dateFormat: settings.dateFormat,
      );
    } else {
      reportItem = await ExcelReportService.generateCustomerExcel(
        profile: activeProfile,
        customer: widget.customer,
        transactions: filteredTxs,
        includeNotes: _includeNotes,
        dateFormat: settings.dateFormat,
      );
    }

    // Save report record
    await ref.read(reportsRepositoryProvider).saveReport(reportItem);
    await ref.read(reportsViewModelProvider.notifier).loadReports();

    return reportItem;
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final report = await _generateReport();
      if (report != null && mounted) {
        AppDialogs.showToast(context, 'Report generated successfully');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExportedReportsView()),
        );
      }
    } catch (e) {
      if (mounted) AppDialogs.showToast(context, 'Failed to generate report: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isExporting = true);
    try {
      final report = await _generateReport();
      if (report != null) {
        await Share.shareXFiles(
          [XFile(report.filePath)],
          text: 'Statement for ${widget.customer.name}',
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) AppDialogs.showToast(context, 'Failed to share report: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider).settings;
    final dateFormat = settings.dateFormat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Filter'),
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Generating Report...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.customer.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (widget.customer.phone != null)
                                Text(
                                  widget.customer.phone!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Format Selector Card (PDF vs Excel)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPORT FORMAT',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _format = 'pdf'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _format == 'pdf' ? const Color(0xFFFFEBEE) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _format == 'pdf' ? AppColors.creditRed : AppColors.border,
                                      width: _format == 'pdf' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.picture_as_pdf_rounded, color: AppColors.creditRed, size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'PDF Statement',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.creditRed),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _format = 'excel'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _format == 'excel' ? AppColors.paymentGreenLight : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _format == 'excel' ? AppColors.paymentGreen : AppColors.border,
                                      width: _format == 'excel' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.table_chart_rounded, color: AppColors.paymentGreen, size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Excel (.xlsx)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.paymentGreen),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATE RANGE',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<DateFilterMode>(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Quick Access', style: TextStyle(fontWeight: FontWeight.w600)),
                                value: DateFilterMode.quickAccess,
                                groupValue: _dateMode,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) setState(() => _dateMode = val);
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<DateFilterMode>(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Between Dates', style: TextStyle(fontWeight: FontWeight.w600)),
                                value: DateFilterMode.betweenTwoDates,
                                groupValue: _dateMode,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) setState(() => _dateMode = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.divider, height: 16),
                        if (_dateMode == DateFilterMode.quickAccess) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: QuickDateOption.values.map((opt) {
                              final isSelected = _quickOption == opt;
                              return ChoiceChip(
                                label: Text(opt.displayName),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) setState(() => _quickOption = opt);
                                },
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickStartDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('From', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(dateFormat).format(_startDate),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickEndDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('To', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(dateFormat).format(_endDate),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                  // Include Notes Switch Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Add transaction notes in customer report?',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: _includeNotes,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _includeNotes = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions: Export & Share
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.share_rounded, color: AppColors.primary),
                          label: const Text(
                            'SHARE',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          onPressed: _handleShare,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text(
                            'EXPORT',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _handleExport,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
