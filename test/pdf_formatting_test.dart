import 'package:flutter_test/flutter_test.dart';
import 'package:hishabify/core/utils/formatters.dart';

void main() {
  group('PDF Currency and Text Formatting Tests', () {
    test('getPdfSafeCurrency converts non-standard PDF glyphs to standard representations', () {
      expect(AppFormatters.getPdfSafeCurrency('৳'), 'Tk');
      expect(AppFormatters.getPdfSafeCurrency('₹'), 'Rs');
      expect(AppFormatters.getPdfSafeCurrency('€'), 'EUR');
      expect(AppFormatters.getPdfSafeCurrency('£'), 'GBP');
      expect(AppFormatters.getPdfSafeCurrency('¥'), 'JPY');
      expect(AppFormatters.getPdfSafeCurrency('\$'), '\$');
      expect(AppFormatters.getPdfSafeCurrency('AED'), 'AED');
      expect(AppFormatters.getPdfSafeCurrency('SAR'), 'SAR');
      expect(AppFormatters.getPdfSafeCurrency('PKR'), 'PKR');
    });

    test('formatPdfCurrency formats numbers with safe currency symbols', () {
      expect(AppFormatters.formatPdfCurrency(600, currency: '৳'), 'Tk 600');
      expect(AppFormatters.formatPdfCurrency(656.50, currency: '৳'), 'Tk 656.5');
      expect(AppFormatters.formatPdfCurrency(0, currency: '৳'), 'Tk 0');
      expect(AppFormatters.formatPdfCurrency(1200, currency: '₹'), 'Rs 1,200');
    });

    test('sanitizeForPdf strips emojis and control characters that trigger tofu cross marks', () {
      expect(AppFormatters.sanitizeForPdf('test transaction 😊 with details 👍'), 'test transaction  with details');
      expect(AppFormatters.sanitizeForPdf(null), '-');
      expect(AppFormatters.sanitizeForPdf('   '), '-');
      expect(AppFormatters.sanitizeForPdf('Regular text 123'), 'Regular text 123');
    });
  });
}
