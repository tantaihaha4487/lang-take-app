import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/image_record.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

class HistoryRepository {
  static const String boxName = 'history_box';

  Future<Box<ImageRecord>> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<ImageRecord>(boxName);
    }
    return await Hive.openBox<ImageRecord>(boxName);
  }

  Future<List<ImageRecord>> getRecords() async {
    final box = await _getBox();
    final records = box.values.toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    return records;
  }

  Stream<List<ImageRecord>> watchRecords() async* {
    final box = await _getBox();
    // Initial value
    yield box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Updates
    yield* box.watch().map((_) => box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }



  Future<void> addRecord(ImageRecord record) async {
    final box = await _getBox();
    await box.put(record.id, record);
  }

  Future<void> deleteRecord(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}

