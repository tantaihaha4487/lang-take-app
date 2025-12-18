import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

class SettingsService {
  static const String _motherLanguageKey = 'mother_language';

  Future<String> getMotherLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_motherLanguageKey) ?? 'English';
  }

  Future<void> setMotherLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_motherLanguageKey, language);
  }
}

final motherLanguageProvider = StateNotifierProvider<MotherLanguageNotifier, String>((ref) {
  return MotherLanguageNotifier(ref.read(settingsServiceProvider));
});

class MotherLanguageNotifier extends StateNotifier<String> {
  final SettingsService _settingsService;

  MotherLanguageNotifier(this._settingsService) : super('English') {
    _load();
  }

  Future<void> _load() async {
    state = await _settingsService.getMotherLanguage();
  }

  Future<void> setLanguage(String language) async {
    await _settingsService.setMotherLanguage(language);
    state = language;
  }
}
