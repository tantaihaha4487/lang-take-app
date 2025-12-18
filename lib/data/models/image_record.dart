import 'package:hive/hive.dart';

part 'image_record.g.dart';

@HiveType(typeId: 0)
class ImageRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final String language;

  @HiveField(4)
  final DateTime createdAt;

  ImageRecord({
    required this.id,
    required this.imagePath,
    required this.subject,
    required this.language,
    required this.createdAt,
  });
}
