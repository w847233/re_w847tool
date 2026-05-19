class GameLibraryItem {
  const GameLibraryItem({
    required this.id,
    required this.title,
    required this.cover,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String cover;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'cover': cover,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory GameLibraryItem.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return GameLibraryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      createdAt: _date(json['createdAt']) ?? now,
      updatedAt: _date(json['updatedAt']) ?? now,
    );
  }
}

DateTime? _date(Object? value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
