class AppSettings {
  final bool appLockEnabled;
  final String dateFormat;
  final String timeFormat;
  final String defaultCurrency;
  final bool disclosedTerms;

  const AppSettings({
    this.appLockEnabled = false,
    this.dateFormat = 'dd MMM yyyy',
    this.timeFormat = 'hh:mm a',
    this.defaultCurrency = '\$',
    this.disclosedTerms = false,
  });

  AppSettings copyWith({
    bool? appLockEnabled,
    String? dateFormat,
    String? timeFormat,
    String? defaultCurrency,
    bool? disclosedTerms,
  }) {
    return AppSettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      disclosedTerms: disclosedTerms ?? this.disclosedTerms,
    );
  }

  static const List<String> availableDateFormats = [
    'dd MMM yyyy', // 09 Oct 2026
    'dd/MM/yyyy',  // 09/10/2026
    'MM/dd/yyyy',  // 10/09/2026
    'yyyy-MM-dd',  // 2026-10-09
  ];

  static const List<String> availableTimeFormats = [
    'hh:mm a',     // 01:10 AM (12 Hour)
    'HH:mm',       // 13:10 (24 Hour)
  ];

  static const List<Map<String, String>> availableCurrencies = [
    {'symbol': '\$', 'name': 'USD - US Dollar (\$)'},
    {'symbol': '₹', 'name': 'INR - Indian Rupee (₹)'},
    {'symbol': '€', 'name': 'EUR - Euro (€)'},
    {'symbol': '£', 'name': 'GBP - British Pound (£)'},
    {'symbol': '৳', 'name': 'BDT - Bangladeshi Taka (৳)'},
    {'symbol': '¥', 'name': 'JPY/CNY - Yen / Yuan (¥)'},
    {'symbol': 'AED', 'name': 'AED - UAE Dirham (AED)'},
    {'symbol': 'SAR', 'name': 'SAR - Saudi Riyal (SAR)'},
    {'symbol': 'PKR', 'name': 'PKR - Pakistani Rupee (Rs)'},
    {'symbol': 'CAD', 'name': 'CAD - Canadian Dollar (C\$)'},
    {'symbol': 'AUD', 'name': 'AUD - Australian Dollar (A\$)'},
  ];
}
