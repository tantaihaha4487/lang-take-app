// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageRecordAdapter extends TypeAdapter<ImageRecord> {
  @override
  final int typeId = 0;

  @override
  ImageRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageRecord(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      subject: fields[2] as String,
      language: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ImageRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
