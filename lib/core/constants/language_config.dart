class AppLanguage {
  final String name;
  final String code;
  final String flag;

  const AppLanguage({
    required this.name,
    required this.code,
    this.flag = '',
  });
}

class LanguageConfig {
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(name: 'English', code: 'en-US', flag: '🇺🇸'),
    AppLanguage(name: 'Thai', code: 'th-TH', flag: '🇹🇭'),
    AppLanguage(name: 'Spanish', code: 'es-ES', flag: '🇪🇸'),
    AppLanguage(name: 'Japanese', code: 'ja-JP', flag: '🇯🇵'),
    AppLanguage(name: 'French', code: 'fr-FR', flag: '🇫🇷'),
    AppLanguage(name: 'German', code: 'de-DE', flag: '🇩🇪'),
    AppLanguage(name: 'Italian', code: 'it-IT', flag: '🇮🇹'),
    AppLanguage(name: 'Chinese', code: 'zh-CN', flag: '🇨🇳'),
    AppLanguage(name: 'Korean', code: 'ko-KR', flag: '🇰🇷'),
    AppLanguage(name: 'Russian', code: 'ru-RU', flag: '🇷🇺'),
    AppLanguage(name: 'Portuguese', code: 'pt-BR', flag: '🇧🇷'),
  ];

  static List<String> get names => supportedLanguages.map((l) => l.name).toList();

  static String getCode(String name) {
    return supportedLanguages.firstWhere(
      (l) => l.name == name,
      orElse: () => supportedLanguages.first,
    ).code;
  }
}
