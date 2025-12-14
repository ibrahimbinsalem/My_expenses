class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final int color;

  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  CategoryModel copyWith({int? id, String? name, String? icon, int? color}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? 'wallet',
      color: map['color'] as int? ?? 0xFF000000,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color};
  }
}
