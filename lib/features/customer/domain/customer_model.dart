import '../../transaction/domain/transaction_model.dart';

class Customer {
  final String id;
  final String profileId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double carryForwardBalance;
  final TransactionType carryForwardType;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Calculated fields (populated in queries / viewmodels)
  final double totalCredit;
  final double totalPayment;
  final DateTime? lastTransactionDate;

  Customer({
    required this.id,
    required this.profileId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.carryForwardBalance = 0.0,
    this.carryForwardType = TransactionType.credit,
    required this.createdAt,
    required this.updatedAt,
    this.totalCredit = 0.0,
    this.totalPayment = 0.0,
    this.lastTransactionDate,
  });

  /// Net balance: positive means customer owes you money (Due),
  /// negative means customer has advance credit with you (Advance),
  /// zero means settled.
  double get netBalance => totalCredit - totalPayment;

  bool get isDue => netBalance > 0;
  bool get isAdvance => netBalance < 0;
  bool get isSettled => netBalance == 0;

  String get balanceStatusText {
    if (isDue) return 'Due';
    if (isAdvance) return 'Advance';
    return 'Settled';
  }

  Customer copyWith({
    String? id,
    String? profileId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? carryForwardBalance,
    TransactionType? carryForwardType,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalCredit,
    double? totalPayment,
    DateTime? lastTransactionDate,
  }) {
    return Customer(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      carryForwardBalance: carryForwardBalance ?? this.carryForwardBalance,
      carryForwardType: carryForwardType ?? this.carryForwardType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalCredit: totalCredit ?? this.totalCredit,
      totalPayment: totalPayment ?? this.totalPayment,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'carry_forward_balance': carryForwardBalance,
      'carry_forward_type': carryForwardType.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, {
    double totalCredit = 0.0,
    double totalPayment = 0.0,
    DateTime? lastTransactionDate,
  }) {
    return Customer(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      carryForwardBalance: (map['carry_forward_balance'] as num?)?.toDouble() ?? 0.0,
      carryForwardType: TransactionType.fromString(map['carry_forward_type'] as String? ?? 'credit'),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      totalCredit: totalCredit,
      totalPayment: totalPayment,
      lastTransactionDate: lastTransactionDate,
    );
  }
}
