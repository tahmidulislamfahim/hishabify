enum TransactionType {
  credit,   // Udhar / Given Credit / Customer owes you / Red
  payment;  // Jama / Accepted Payment / Advance / Green

  String get displayName => this == credit ? 'Credit' : 'Payment';
  String get actionTitle => this == credit ? 'Give Credit' : 'Accept Payment';

  static TransactionType fromString(String val) {
    return val.toLowerCase() == 'payment' ? TransactionType.payment : TransactionType.credit;
  }
}

class TransactionItem {
  final String id;
  final String profileId;
  final String customerId;
  final double amount;
  final TransactionType type;
  final DateTime dateTime;
  final String? note;
  final bool isCarryForward;
  final String? customerName;

  TransactionItem({
    required this.id,
    required this.profileId,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.dateTime,
    this.note,
    this.isCarryForward = false,
    this.customerName,
  });

  TransactionItem copyWith({
    String? id,
    String? profileId,
    String? customerId,
    double? amount,
    TransactionType? type,
    DateTime? dateTime,
    String? note,
    bool? isCarryForward,
    String? customerName,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      isCarryForward: isCarryForward ?? this.isCarryForward,
      customerName: customerName ?? this.customerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'customer_id': customerId,
      'amount': amount,
      'type': type.name,
      'date_time': dateTime.toIso8601String(),
      'note': note,
      'is_carry_forward': isCarryForward ? 1 : 0,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map, {String? customerName}) {
    return TransactionItem(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      customerId: map['customer_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String),
      dateTime: DateTime.parse(map['date_time'] as String),
      note: map['note'] as String?,
      isCarryForward: (map['is_carry_forward'] as int? ?? 0) == 1,
      customerName: customerName ?? map['customer_name'] as String?,
    );
  }
}
