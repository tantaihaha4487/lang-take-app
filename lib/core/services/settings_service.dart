import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

class SettingsService {
  static const String _motherLanguageKey = 'mother_language';
  static const String _targetLanguageKey = 'target_language';
  static const String _appLanguageKey = 'app_language';
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _fontWeightKey = 'font_weight';
  static const String _themeModeKey = 'theme_mode';




  Future<String> getMotherLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_motherLanguageKey) ?? 'English';
  }

  Future<void> setMotherLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_motherLanguageKey, language);
  }

  Future<String> getTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_targetLanguageKey) ?? 'Spanish';
  }

  Future<void> setTargetLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetLanguageKey, language);
  }

  Future<String> getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appLanguageKey) ?? 'English';
  }

  Future<void> setAppLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, language);
  }


  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  Future<void> setFirstTimeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }

  Future<void> resetFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, true);
  }

  Future<int> getFontWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_fontWeightKey) ?? 200;
  }

  Future<void> setFontWeight(int weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontWeightKey, weight);
  }

  Future<bool> getIsLightMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeModeKey) ?? true;
  }

  Future<void> setIsLightMode(bool isLight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, isLight);
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

final fontWeightProvider = StateNotifierProvider<FontWeightNotifier, int>((ref) {
  return FontWeightNotifier(ref.read(settingsServiceProvider));
});

class FontWeightNotifier extends StateNotifier<int> {
  final SettingsService _settingsService;

  FontWeightNotifier(this._settingsService) : super(200) {
    _load();
  }

  Future<void> _load() async {
    state = await _settingsService.getFontWeight();
  }

  Future<void> setWeight(int weight) async {
    await _settingsService.setFontWeight(weight);
    state = weight;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier(ref.read(settingsServiceProvider));
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final SettingsService _settingsService;

  ThemeModeNotifier(this._settingsService) : super(true) {
    _load();
  }

  Future<void> _load() async {
    state = await _settingsService.getIsLightMode();
  }

  Future<void> setLightMode(bool isLight) async {
    await _settingsService.setIsLightMode(isLight);
    state = isLight;
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, String>((ref) {
  return AppLanguageNotifier(ref.read(settingsServiceProvider));
});

class AppLanguageNotifier extends StateNotifier<String> {
  final SettingsService _settingsService;

  AppLanguageNotifier(this._settingsService) : super('English') {
    _load();
  }

  Future<void> _load() async {
    state = await _settingsService.getAppLanguage();
  }

  Future<void> setLanguage(String language) async {
    await _settingsService.setAppLanguage(language);
    state = language;
  }
}

