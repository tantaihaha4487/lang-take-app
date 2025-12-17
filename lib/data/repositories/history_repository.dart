import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_item.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

class HistoryRepository {
  Future<File> _getHistoryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/history.json');
  }

  Future<List<HistoryItem>> getHistory() async {
    try {
      final file = await _getHistoryFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => HistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistoryItem(HistoryItem item) async {
    final history = await getHistory();
    history.insert(0, item);
    final file = await _getHistoryFile();
    await file.writeAsString(jsonEncode(history.map((e) => e.toJson()).toList()));
  }
}
