class HistoryItem {
  final String id;
  final String name;
  final String pronunciation;
  final String translation;
  final String description;
  final DateTime timestamp;
  final String imagePath;

  HistoryItem({
    required this.id,
    required this.name,
    required this.pronunciation,
    required this.translation,
    required this.description,
    required this.timestamp,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pronunciation': pronunciation,
      'translation': translation,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      name: json['name'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      translation: json['translation'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'] ?? '',
    );
  }
}
