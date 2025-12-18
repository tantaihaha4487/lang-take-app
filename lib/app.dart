import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/services/settings_service.dart';

final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final settings = ref.read(settingsServiceProvider);
  return settings.isFirstTime();
});


class LangTakeApp extends ConsumerWidget {
  const LangTakeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingStatusProvider);

    return MaterialApp(
      title: 'LangTake Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: onboardingAsync.when(
        data: (isFirstTime) => isFirstTime ? const OnboardingScreen() : const MainScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const MainScreen(),
      ),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}


