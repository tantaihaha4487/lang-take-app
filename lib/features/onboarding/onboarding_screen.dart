import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../core/constants/language_config.dart';
import '../../core/services/settings_service.dart';
import '../../core/widgets/interactive_glass_container.dart';
import '../camera/camera_view_model.dart';
import '../../core/constants/app_locales.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedAppLanguage = 'English';
  String _selectedTargetLanguage = 'Spanish';
  String _selectedMotherLanguage = 'English';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final settings = ref.read(settingsServiceProvider);
    await settings.setMotherLanguage(_selectedMotherLanguage);
    await settings.setTargetLanguage(_selectedTargetLanguage);
    await settings.setAppLanguage(_selectedAppLanguage);
    await settings.setFirstTimeCompleted();
    
    // Refresh providers
    ref.read(motherLanguageProvider.notifier).setLanguage(_selectedMotherLanguage);
    ref.read(cameraViewModelProvider.notifier).setTargetLanguage(_selectedTargetLanguage);
    ref.read(appLanguageProvider.notifier).setLanguage(_selectedAppLanguage);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient - Isolated with RepaintBoundary
          const RepaintBoundary(
            child: _BackgroundGradient(),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildProgressIndicator(),
                Expanded(
                  child: RepaintBoundary(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildAppLanguageStep(),
                        _buildTargetLanguageStep(),
                        _buildMotherLanguageStep(),
                      ],
                    ),
                  ),
                ),
                _buildBottomControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isSelected ? 24 : 8,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildStepContainer({
    required String title,
    String? subtitle,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: Theme.of(context).textTheme.displayLarge?.fontWeight,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 48),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildAppLanguageStep() {
    final locale = ref.read(appLocaleProvider);
    return _buildStepContainer(
      title: locale.appLanguage,
      subtitle: locale.appLanguageSub,
      content: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                lang: LanguageConfig.supportedLanguages.firstWhere((l) => l.name == 'English'),
                isSelected: _selectedAppLanguage == 'English',
                onTap: () {
                  setState(() => _selectedAppLanguage = 'English');
                  ref.read(appLanguageProvider.notifier).setLanguage('English');
                },
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                lang: LanguageConfig.supportedLanguages.firstWhere((l) => l.name == 'Thai'),
                isSelected: _selectedAppLanguage == 'Thai',
                onTap: () {
                  setState(() => _selectedAppLanguage = 'Thai');
                  ref.read(appLanguageProvider.notifier).setLanguage('Thai');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetLanguageStep() {
    final locale = ref.read(appLocaleProvider);
    return _buildStepContainer(
      title: locale.learnLanguage,
      subtitle: locale.learnLanguageSub,
      content: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: LanguageConfig.supportedLanguages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = LanguageConfig.supportedLanguages[index];
          return _buildLanguageOption(
            lang: lang,
            isSelected: _selectedTargetLanguage == lang.name,
            onTap: () => setState(() => _selectedTargetLanguage = lang.name),
          );
        },
      ),
    );
  }

  Widget _buildMotherLanguageStep() {
    final locale = ref.read(appLocaleProvider);
    return _buildStepContainer(
      title: locale.motherLanguage,
      subtitle: '',
      content: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: LanguageConfig.supportedLanguages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = LanguageConfig.supportedLanguages[index];
          return _buildLanguageOption(
            lang: lang,
            isSelected: _selectedMotherLanguage == lang.name,
            onTap: () => setState(() => _selectedMotherLanguage = lang.name),
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption({
    required AppLanguage lang,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InteractiveGlassContainer(
      onTap: onTap,
      borderRadius: 20,
      blur: 15,
      // Performance optimization: only use blur for selected item or if it's the first step
      useBlur: isSelected || _currentPage == 0,
      color: isSelected ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.05),
      border: Border.all(
        color: isSelected ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.1),
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            lang.flag,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 16),
          Text(
            lang.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: isSelected ? Theme.of(context).textTheme.bodyLarge?.fontWeight : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final locale = ref.read(appLocaleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            InteractiveGlassContainer(
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
              ),
              borderRadius: 20,
              useBlur: false, // Optimization for buttons
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                locale.back,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: Theme.of(context).textTheme.bodyLarge?.fontWeight,
                ),
              ),
            )
          else
            const SizedBox(width: 80),
          
          InteractiveGlassContainer(
            onTap: _nextPage,
            borderRadius: 20,
            useBlur: false, // Optimization for buttons
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Text(
              _currentPage == 2 ? locale.getStarted : locale.next,
              style: TextStyle(
                color: Colors.black,
                fontWeight: Theme.of(context).textTheme.bodyLarge?.fontWeight,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
      ),
    );
  }
}

