class CurrencyModel {
  final int? id;
  final String code;
  final String name;
  final bool isDefault;

  const CurrencyModel({
    this.id,
    required this.code,
    required this.name,
    this.isDefault = false,
  });

  CurrencyModel copyWith({
    int? id,
    String? code,
    String? name,
    bool? isDefault,
  }) {
    return CurrencyModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'is_default': isDefault ? 1 : 0,
    };
  }
}
