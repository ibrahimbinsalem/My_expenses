enum RecurringFrequency { weekly, monthly, quarterly, yearly }

class RecurringTaskModel {
  final int? id;
  final String title;
  final String? description;
  final double? amount;
  final String? currency;
  final RecurringFrequency frequency;
  final DateTime nextDate;
  final int? walletId;
  final DateTime createdAt;

  const RecurringTaskModel({
    this.id,
    required this.title,
    this.description,
    this.amount,
    this.currency,
    required this.frequency,
    required this.nextDate,
    this.walletId,
    required this.createdAt,
  });

  RecurringTaskModel copyWith({
    int? id,
    String? title,
    String? description,
    double? amount,
    String? currency,
    RecurringFrequency? frequency,
    DateTime? nextDate,
    int? walletId,
    DateTime? createdAt,
  }) {
    return RecurringTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      walletId: walletId ?? this.walletId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RecurringTaskModel.fromMap(Map<String, dynamic> map) {
    return RecurringTaskModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      currency: map['currency'] as String?,
      frequency: _frequencyFromString(map['frequency'] as String? ?? 'monthly'),
      nextDate: DateTime.parse(map['next_date'] as String),
      walletId: map['wallet_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'frequency': frequency.name,
      'next_date': nextDate.toIso8601String(),
      'wallet_id': walletId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static RecurringFrequency _frequencyFromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (freq) => freq.name == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}
