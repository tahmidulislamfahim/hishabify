import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../core/utils/formatters.dart';
import '../../../settings/presentation/viewmodels/settings_viewmodel.dart';
import '../viewmodels/reports_viewmodel.dart';

class ExportedReportsView extends ConsumerWidget {
  const ExportedReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider).settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exported Reports'),
        actions: [
          IconButton(
            icon: Icon(
              reportsState.isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            ),
            onPressed: () {
              ref.read(reportsViewModelProvider.notifier).toggleSort();
            },
            tooltip: reportsState.isAscending ? 'Sort Oldest First' : 'Sort Newest First',
          ),
        ],
      ),
      body: reportsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : reportsState.reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Exported Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your generated PDF & Excel statements\nwill appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reportsState.reports.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    thickness: 0.8,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final report = reportsState.reports[index];
                    final isPdf = report.fileType.toLowerCase() == 'pdf';
                    final sizeKb = (report.fileSize / 1024).toStringAsFixed(1);
                    final formattedDate = AppFormatters.formatDateTime(
                      report.createdAt,
                      dateFormat: settings.dateFormat,
                      timeFormat: settings.timeFormat,
                    );

                    return Material(
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isPdf ? const Color(0xFFFFEBEE) : AppColors.paymentGreenLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded,
                            color: isPdf ? AppColors.creditRed : AppColors.paymentGreen,
                            size: 26,
                          ),
                        ),
                        title: Text(
                          report.fileName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '$formattedDate  •  $sizeKb KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                          onSelected: (val) async {
                            if (val == 'open') {
                              await ref.read(reportsViewModelProvider.notifier).openReport(report);
                            } else if (val == 'share') {
                              await ref.read(reportsViewModelProvider.notifier).shareReport(report);
                            } else if (val == 'delete') {
                              final confirm = await AppDialogs.showConfirmDialog(
                                context: context,
                                title: 'Delete Report',
                                message: 'Are you sure you want to permanently delete this report file?',
                                confirmText: 'DELETE',
                                isDestructive: true,
                              );
                              if (confirm == true) {
                                await ref
                                    .read(reportsViewModelProvider.notifier)
                                    .deleteReport(report.id, report.filePath);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                                  SizedBox(width: 12),
                                  Text('Open'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, size: 20, color: AppColors.primary),
                                  SizedBox(width: 12),
                                  Text('Share'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: AppColors.creditRed),
                                  SizedBox(width: 12),
                                  Text('Delete', style: TextStyle(color: AppColors.creditRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          ref.read(reportsViewModelProvider.notifier).openReport(report);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
