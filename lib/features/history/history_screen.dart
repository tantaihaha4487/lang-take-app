import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../data/models/image_record.dart';
import '../../data/repositories/history_repository.dart';
import '../../core/services/tts_service.dart';
import '../../core/constants/language_config.dart';
import '../../core/widgets/interactive_glass_container.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/constants/app_locales.dart';





final historyProvider = StreamProvider<List<ImageRecord>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.watchRecords();
});



class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => ref.read(navigationIndexProvider.notifier).state = 0,
              ),
              title: Text(
                locale.album,
                style: const TextStyle(fontWeight: FontWeight.w200, letterSpacing: 1),
              ),
              elevation: 0,
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient - Isolated with RepaintBoundary
          const RepaintBoundary(
            child: _HistoryBackground(),
          ),
          
          historyAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return _buildEmptyState(locale);
              }

              return RepaintBoundary(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 32, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return _HistoryCard(record: records[index], index: index);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            error: (err, stack) => _buildErrorState(err),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocale locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            locale.noPhotos,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
          Text(
            locale.goTakeSome,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final ImageRecord record;
  final int index;

  const _HistoryCard({Key? key, required this.record, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsService = ref.watch(ttsServiceProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 600)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InteractiveGlassContainer(
        onTap: () => ttsService.speak(record.subject, language: record.language),
        borderRadius: 24,
        useBlur: false, // Optimization: disable blur for grid items
        scaleOnTap: 0.96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Area
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(record.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.broken_image, color: Colors.white24),
                      );
                    },
                  ),
                  // 2. Language Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildLanguageBadge(),
                  ),
                ],
              ),
            ),
            
            // 3. Content Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTextInfo(),
                    _buildDateInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBadge() {
    final langData = LanguageConfig.supportedLanguages.firstWhere(
      (l) => l.name == record.language,
      orElse: () => LanguageConfig.supportedLanguages.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(langData.flag, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            record.language,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.subject,
                style: const TextStyle(fontWeight: FontWeight.w200, fontSize: 16, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              if (record.translation != null)
                Text(
                  record.translation!,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Icon(Icons.volume_up, color: Colors.white.withOpacity(0.5), size: 18),
      ],
    );
  }

  Widget _buildDateInfo() {
    return Text(
      "${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}",
      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
    );
  }
}

class _HistoryBackground extends StatelessWidget {
  const _HistoryBackground();

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

