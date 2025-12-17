class BillParticipantModel {
  final int? id;
  final int billId;
  final String name;
  final double share;
  final double paid;
  final int? walletId;

  const BillParticipantModel({
    this.id,
    required this.billId,
    required this.name,
    required this.share,
    this.paid = 0,
    this.walletId,
  });

  BillParticipantModel copyWith({
    int? id,
    int? billId,
    String? name,
    double? share,
    double? paid,
    int? walletId,
  }) {
    return BillParticipantModel(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      name: name ?? this.name,
      share: share ?? this.share,
      paid: paid ?? this.paid,
      walletId: walletId ?? this.walletId,
    );
  }

  factory BillParticipantModel.fromMap(Map<String, dynamic> map) {
    return BillParticipantModel(
      id: map['id'] as int?,
      billId: map['bill_id'] as int,
      name: map['name'] as String? ?? '',
      share: (map['share'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      walletId: map['wallet_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'name': name,
      'share': share,
      'paid': paid,
      'wallet_id': walletId,
    };
  }
}

class BillGroupModel {
  final int? id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final double total;
  final String currency;
  final DateTime createdAt;
  final List<BillParticipantModel> participants;

  const BillGroupModel({
    this.id,
    required this.title,
    this.description,
    required this.eventDate,
    required this.total,
    required this.currency,
    required this.createdAt,
    this.participants = const [],
  });

  BillGroupModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    double? total,
    String? currency,
    DateTime? createdAt,
    List<BillParticipantModel>? participants,
  }) {
    return BillGroupModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
    );
  }

  factory BillGroupModel.fromMap(Map<String, dynamic> map) {
    return BillGroupModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      eventDate: DateTime.parse(map['event_date'] as String),
      total: (map['total'] as num).toDouble(),
      currency: map['currency'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      participants: const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'total': total,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
