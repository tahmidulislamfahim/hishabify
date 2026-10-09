import 'package:flutter/material.dart';

enum DateFilterMode {
  quickAccess,
  betweenTwoDates;
}

typedef QuickDateOption = QuickAccessDateOption;

enum QuickAccessDateOption {
  all,
  today,
  yesterday,
  lastWeek,
  thisMonth,
  lastMonth;

  String get displayName {
    switch (this) {
      case QuickAccessDateOption.all:
        return 'All';
      case QuickAccessDateOption.today:
        return 'Today';
      case QuickAccessDateOption.yesterday:
        return 'Yesterday';
      case QuickAccessDateOption.lastWeek:
        return 'Last Week';
      case QuickAccessDateOption.thisMonth:
        return 'This Month';
      case QuickAccessDateOption.lastMonth:
        return 'Last Month';
    }
  }
}

enum FilterTypeOption {
  all,
  credits,
  payments;

  String get displayName {
    switch (this) {
      case FilterTypeOption.all:
        return 'All';
      case FilterTypeOption.credits:
        return 'Credits (Udhar)';
      case FilterTypeOption.payments:
        return 'Payments (Jama)';
    }
  }
}

class TransactionFilter {
  final QuickAccessDateOption quickAccess;
  final bool isCustomDateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final FilterTypeOption typeFilter;
  final String? selectedCustomerId;
  final String? selectedCustomerName;

  DateFilterMode get dateMode =>
      isCustomDateRange ? DateFilterMode.betweenTwoDates : DateFilterMode.quickAccess;
  QuickAccessDateOption get quickDate => quickAccess;

  const TransactionFilter({
    QuickAccessDateOption? quickAccess,
    QuickAccessDateOption? quickDate,
    DateFilterMode? dateMode,
    bool isCustomDateRange = false,
    this.customStartDate,
    this.customEndDate,
    this.typeFilter = FilterTypeOption.all,
    this.selectedCustomerId,
    this.selectedCustomerName,
  })  : quickAccess = quickDate ?? quickAccess ?? QuickAccessDateOption.all,
        isCustomDateRange = dateMode == DateFilterMode.betweenTwoDates || isCustomDateRange;

  DateTimeRange? get effectiveDateRange {
    final now = DateTime.now();

    if (isCustomDateRange) {
      if (customStartDate != null && customEndDate != null) {
        final start = DateTime(customStartDate!.year, customStartDate!.month, customStartDate!.day, 0, 0, 0);
        final end = DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      }
      return null;
    }

    switch (quickAccess) {
      case QuickAccessDateOption.all:
        return null;
      case QuickAccessDateOption.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case QuickAccessDateOption.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case QuickAccessDateOption.lastWeek:
        final lastWeekStart = now.subtract(const Duration(days: 7));
        final start = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case QuickAccessDateOption.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case QuickAccessDateOption.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
    }
  }

  TransactionFilter copyWith({
    QuickAccessDateOption? quickAccess,
    bool? isCustomDateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    FilterTypeOption? typeFilter,
    String? selectedCustomerId,
    String? selectedCustomerName,
    bool clearCustomer = false,
  }) {
    return TransactionFilter(
      quickAccess: quickAccess ?? this.quickAccess,
      isCustomDateRange: isCustomDateRange ?? this.isCustomDateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      typeFilter: typeFilter ?? this.typeFilter,
      selectedCustomerId: clearCustomer ? null : (selectedCustomerId ?? this.selectedCustomerId),
      selectedCustomerName: clearCustomer ? null : (selectedCustomerName ?? this.selectedCustomerName),
    );
  }
}
