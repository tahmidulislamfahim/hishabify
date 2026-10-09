import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import '../../../core/utils/formatters.dart';
import '../../customer/domain/customer_model.dart';
import '../../profile/domain/profile_model.dart';
import '../../transaction/domain/transaction_model.dart';
import '../domain/report_file_model.dart';

class PdfReportService {
  static Future<ReportFileItem> generateCustomerStatement({
    required Profile profile,
    required Customer customer,
    required List<TransactionItem> transactions,
    required bool includeNotes,
    required String dateFormat,
  }) async {
    final pdf = pw.Document();

    double totalPayment = 0.0;
    double totalCredit = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.payment) {
        totalPayment += tx.amount;
      } else {
        totalCredit += tx.amount;
      }
    }
    final netBalance = totalCredit - totalPayment;
    final isDue = netBalance > 0;
    final statusText = isDue ? '(due)' : (netBalance < 0 ? '(advance)' : '(settled)');
    final todayFormatted = DateFormat(dateFormat).format(DateTime.now());

    // Color definitions
    const tealColor = PdfColor.fromInt(0xFF0097A7);
    const greenColor = PdfColor.fromInt(0xFF2E7D32);
    const redColor = PdfColor.fromInt(0xFFE53935);
    const grayBg = PdfColor.fromInt(0xFFF8FAFC);
    const borderColor = PdfColor.fromInt(0xFFE2E8F0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Bar
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: tealColor, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile.name,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: tealColor,
                        ),
                      ),
                      pw.Text(
                        'Credit & Debit Statement',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Hishabify',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: tealColor,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Customer Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: grayBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('Name : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      pw.Text(customer.name, style: const pw.TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('Phone : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                        pw.Text(customer.phone!, style: const pw.TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                  if (customer.address != null && customer.address!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('Address : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                        pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Final Balance $todayFormatted : ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                      ),
                      pw.Text(
                        '${AppFormatters.formatCurrency(netBalance, currency: profile.currency)} $statusText',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: isDue ? redColor : greenColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Transactions Table
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: grayBg),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('DATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'PAYMENT',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: greenColor),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'CREDIT',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: redColor),
                      ),
                    ),
                    if (includeNotes)
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('NOTE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                  ],
                ),
                // Data rows
                for (int i = 0; i < transactions.length; i++) ...[
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i % 2 == 1 ? const PdfColor(0.98, 0.98, 0.99) : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          DateFormat(dateFormat).format(transactions[i].dateTime),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          transactions[i].type == TransactionType.payment
                              ? AppFormatters.formatCurrency(transactions[i].amount, currency: profile.currency)
                              : '-',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: transactions[i].type == TransactionType.payment ? greenColor : PdfColors.black,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          transactions[i].type == TransactionType.credit
                              ? AppFormatters.formatCurrency(transactions[i].amount, currency: profile.currency)
                              : '-',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: transactions[i].type == TransactionType.credit ? redColor : PdfColors.black,
                          ),
                        ),
                      ),
                      if (includeNotes)
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(transactions[i].note ?? '-', style: const pw.TextStyle(fontSize: 9)),
                        ),
                    ],
                  ),
                ],
                // TOTAL row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: grayBg),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        AppFormatters.formatCurrency(totalPayment, currency: profile.currency),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: greenColor),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        AppFormatters.formatCurrency(totalCredit, currency: profile.currency),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: redColor),
                      ),
                    ),
                    if (includeNotes)
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Final Balance Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Final Balance $todayFormatted :',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                  pw.Text(
                    '${AppFormatters.formatCurrency(netBalance, currency: profile.currency)} $statusText',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: isDue ? redColor : greenColor,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Save to device storage
    final outputDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(outputDir.path, 'CreditReport'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'List_$timestamp.pdf';
    final file = File(p.join(reportsDir.path, fileName));
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    return ReportFileItem(
      id: const Uuid().v4(),
      filePath: file.path,
      fileName: fileName,
      fileType: 'pdf',
      fileSize: bytes.length,
      createdAt: DateTime.now(),
    );
  }
}
