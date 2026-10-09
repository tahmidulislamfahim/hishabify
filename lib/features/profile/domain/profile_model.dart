enum ProfileType {
  business,
  personal;

  String get displayName => this == business ? 'Business' : 'Personal';

  static ProfileType fromString(String val) {
    return val.toLowerCase() == 'personal' ? ProfileType.personal : ProfileType.business;
  }
}

class Profile {
  final String id;
  final String name;
  final ProfileType type;
  final String currency;
  final bool isDefault;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.isDefault = false,
    required this.createdAt,
  });

  Profile copyWith({
    String? id,
    String? name,
    ProfileType? type,
    String? currency,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'currency': currency,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ProfileType.fromString(map['type'] as String),
      currency: map['currency'] as String? ?? '\$',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
