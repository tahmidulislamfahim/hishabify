import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../customer/domain/customer_model.dart';
import '../../profile/domain/profile_model.dart';
import '../../transaction/domain/transaction_model.dart';
import '../domain/report_file_model.dart';

class ExcelReportService {
  static Future<ReportFileItem> generateCustomerExcel({
    required Profile profile,
    required Customer customer,
    required List<TransactionItem> transactions,
    required bool includeNotes,
    required String dateFormat,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Statement'];
    excel.setDefaultSheet('Statement');

    // Customer info header
    sheet.appendRow([TextCellValue('Hishabify - Statement')]);
    sheet.appendRow([TextCellValue('Business: ${profile.name}')]);
    sheet.appendRow([TextCellValue('Customer: ${customer.name}')]);
    if (customer.phone != null) {
      sheet.appendRow([TextCellValue('Phone: ${customer.phone!}')]);
    }
    sheet.appendRow([
      TextCellValue('Generated: ${DateFormat(dateFormat).format(DateTime.now())}')
    ]);
    sheet.appendRow([TextCellValue('')]); // empty line

    // Column headers
    final headers = [
      TextCellValue('S.No'),
      TextCellValue('Date'),
      TextCellValue('Payment (${profile.currency})'),
      TextCellValue('Credit (${profile.currency})'),
    ];
    if (includeNotes) {
      headers.add(TextCellValue('Note'));
    }
    sheet.appendRow(headers);

    double totalPayment = 0.0;
    double totalCredit = 0.0;

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final isPayment = tx.type == TransactionType.payment;
      if (isPayment) {
        totalPayment += tx.amount;
      } else {
        totalCredit += tx.amount;
      }

      final row = [
        IntCellValue(i + 1),
        TextCellValue(DateFormat(dateFormat).format(tx.dateTime)),
        DoubleCellValue(isPayment ? tx.amount : 0.0),
        DoubleCellValue(!isPayment ? tx.amount : 0.0),
      ];
      if (includeNotes) {
        row.add(TextCellValue(tx.note ?? ''));
      }
      sheet.appendRow(row);
    }

    // Totals
    final totalRow = [
      TextCellValue('TOTAL'),
      TextCellValue(''),
      DoubleCellValue(totalPayment),
      DoubleCellValue(totalCredit),
    ];
    if (includeNotes) {
      totalRow.add(TextCellValue(''));
    }
    sheet.appendRow(totalRow);

    final netBalance = totalCredit - totalPayment;
    sheet.appendRow([
      TextCellValue('NET BALANCE (${profile.currency})'),
      TextCellValue(netBalance > 0 ? 'Due' : (netBalance < 0 ? 'Advance' : 'Settled')),
      DoubleCellValue(netBalance),
    ]);

    // Save
    final outputDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(outputDir.path, 'CreditReport'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'List_$timestamp.xlsx';
    final file = File(p.join(reportsDir.path, fileName));
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }

    return ReportFileItem(
      id: const Uuid().v4(),
      filePath: file.path,
      fileName: fileName,
      fileType: 'excel',
      fileSize: fileBytes?.length ?? 0,
      createdAt: DateTime.now(),
    );
  }
}
