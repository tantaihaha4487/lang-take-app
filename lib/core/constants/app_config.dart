import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  final bool showResetOnboarding;

  AppConfig({
    this.showResetOnboarding = true,
  });
}

final appConfigProvider = Provider<AppConfig>((ref) {
  // Reads from config.json via --dart-define-from-file
  const showReset = bool.fromEnvironment('SHOW_RESET_ONBOARDING', defaultValue: false);
  
  return AppConfig(
    showResetOnboarding: showReset,
  );
});

