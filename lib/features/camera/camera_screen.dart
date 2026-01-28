import 'dart:io' show Platform;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_view_model.dart';
import '../../core/constants/language_config.dart';
import '../../core/services/settings_service.dart';
import '../../core/widgets/interactive_glass_container.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/constants/app_locales.dart';
import '../../core/constants/app_config.dart';







class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _cameraNotSupported = false;
  String _errorMessage = '';

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  final ImagePicker _imagePicker = ImagePicker();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!kIsWeb && Platform.isLinux) {
      debugPrint('CameraScreen: Camera has limited support on Linux. Using image picker as fallback.');
    }
    
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        _maxAvailableZoom = await _controller!.getMaxZoomLevel();
        _minAvailableZoom = await _controller!.getMinZoomLevel();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraNotSupported = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cameraNotSupported = true;
            _errorMessage = 'No cameras found on this device';
          });
        }
      }
    } on CameraException catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        setState(() {
          _cameraNotSupported = true;
          _errorMessage = 'Camera error: ${e.description}';
        });
      }
    } on MissingPluginException catch (e) {
      debugPrint('Camera plugin not available on this platform: $e');
      if (mounted) {
        setState(() {
          _cameraNotSupported = true;
          _errorMessage = 'Camera not supported on this platform';
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _cameraNotSupported = true;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        ref.read(cameraViewModelProvider.notifier).analyzeFromBytes(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
    await _controller!.setZoomLevel(_currentScale);
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    final offset = details.localPosition;
    final screenSize = MediaQuery.of(context).size;
    final point = Offset(offset.dx / screenSize.width, offset.dy / screenSize.height);
    _controller!.setFocusPoint(point);
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraViewModelProvider);
    final viewModel = ref.read(cameraViewModelProvider.notifier);

    // Fallback UI for Linux/No Camera
    if (_cameraNotSupported) {
      return _buildFallbackUI(cameraState, viewModel);
    }

    // Loading State
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Background Gradient
          const RepaintBoundary(
            child: _CameraBackground(),
          ),
          
          // Layer 1: Camera Preview or Captured Image
          RepaintBoundary(
            child: _buildMainContent(cameraState),
          ),
          
          // Layer 2: UI Overlays
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(cameraState, viewModel),
                const Spacer(),
                _buildBottomArea(cameraState, viewModel),
              ],
            ),
          ),

          // Error Message Toast
          if (cameraState.errorMessage != null)
            _buildErrorToast(cameraState.errorMessage!),
        ],
      ),
    );
  }

  Widget _buildMainContent(CameraState cameraState) {
    if (cameraState.isReviewing && cameraState.capturedImage != null) {
      return Image.memory(cameraState.capturedImage!, fit: BoxFit.cover);
    }
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onTapUp: _onTapUp,
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildBottomArea(CameraState cameraState, CameraViewModel viewModel) {
    if (cameraState.isAnalyzing) {
      return _buildLoadingIndicator();
    } else if (cameraState.identifiedResult != null) {
      return _buildResultCard(cameraState, viewModel);
    } else if (cameraState.isReviewing) {
      return _buildReviewControls(viewModel);
    } else {
      return _buildCaptureControl(viewModel);
    }
  }

  Widget _buildErrorToast(String message) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTopBar(CameraState state, CameraViewModel viewModel) {
    final locale = ref.watch(appLocaleProvider);
    return InteractiveGlassContainer(
      borderRadius: 30,
      blur: 15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale.learnPrompt,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          DropdownButton<String>(
            value: state.targetLanguage,
            dropdownColor: Colors.black.withOpacity(0.8),
            style: TextStyle(
              color: Colors.white,
              fontWeight: Theme.of(context).textTheme.bodyLarge?.fontWeight,
              fontSize: 16,
            ),
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: LanguageConfig.supportedLanguages.map((AppLanguage lang) {
              return DropdownMenuItem<String>(
                value: lang.name,
                child: Row(
                  children: [
                    Text(lang.flag),
                    const SizedBox(width: 8),
                    Text(lang.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                viewModel.setTargetLanguage(newValue);
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SettingsDialog(),
    );
  }



  Widget _buildCaptureControl(CameraViewModel viewModel) {
    final locale = ref.watch(appLocaleProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Upload Button (Bottom Left)
          Align(
            alignment: Alignment.centerLeft,
            child: InteractiveGlassContainer(
              onTap: _pickImage,
              borderRadius: 25,
              blur: 10,
              scaleOnTap: 0.9,
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.file_upload_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Capture Button (Center)
          InteractiveGlassContainer(
            onTap: () => viewModel.capture(_controller!),
            borderRadius: 45,
            blur: 5,
            scaleOnTap: 0.85,
            color: Colors.white.withOpacity(0.1),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              ),
              child: Center(
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Album Button (Bottom Right)
          Align(
            alignment: Alignment.centerRight,
            child: InteractiveGlassContainer(
              onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
              borderRadius: 25,
              blur: 10,
              scaleOnTap: 0.9,
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildReviewControls(CameraViewModel viewModel) {
    final locale = ref.watch(appLocaleProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGlassButton(
            onPressed: viewModel.retake,
            icon: Icons.refresh,
            label: locale.retake,
            isPrimary: false,
            context: context,
          ),
          _buildGlassButton(
            onPressed: () {
              final motherLang = ref.read(motherLanguageProvider);
              viewModel.identify(motherLang);
            },
            icon: Icons.auto_awesome,
            label: locale.identify,
            isPrimary: true,
            context: context,
          ),

        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required BuildContext context,
  }) {
    return InteractiveGlassContainer(
      onTap: onPressed,
      borderRadius: 20,
      color: isPrimary ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontWeight: Theme.of(context).textTheme.bodyLarge?.fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildLoadingIndicator() {
    final locale = ref.watch(appLocaleProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            locale.analyzing,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: Theme.of(context).textTheme.bodyLarge?.fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(CameraState state, CameraViewModel viewModel, {VoidCallback? onNewCapture}) {
    final result = state.identifiedResult;
    final locale = ref.watch(appLocaleProvider);
    if (result == null) return const SizedBox.shrink();

    final subject = result['subject'] ?? 'Unknown';
    final language = result['language'] ?? state.targetLanguage;
    final translation = result['translation'];


    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: Theme.of(context).textTheme.bodySmall?.fontWeight,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.subjectLabel,
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                              ),
                              Text(
                                subject,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: Theme.of(context).textTheme.displayLarge?.fontWeight,
                                ),
                              ),
                              if (translation != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  locale.translationLabel,
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                ),
                                Text(
                                  translation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildGlassIconButton(
                          onPressed: viewModel.speakResult,
                          icon: Icons.volume_up,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    InteractiveGlassContainer(
                      onTap: onNewCapture ?? viewModel.retake,
                      borderRadius: 20,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          locale.newCapture,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: Theme.of(context).textTheme.bodyLarge?.fontWeight,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
                    onPressed: viewModel.resetResultOnly,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({required VoidCallback onPressed, required IconData icon}) {
    return InteractiveGlassContainer(
      onTap: onPressed,
      borderRadius: 15,
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }



  Widget _buildFallbackUI(CameraState state, CameraViewModel viewModel) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               // Top Bar for fallback
              _buildTopBar(state, viewModel),
              const SizedBox(height: 40),
              
              // 1. No Image: Show Picker
              if (state.capturedImage == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage.isNotEmpty 
                          ? _errorMessage 
                          : 'Camera not available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: state.isAnalyzing ? null : _pickImage,
                      icon: state.isAnalyzing 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(state.isAnalyzing ? 'Analyzing...' : 'Pick from Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Image Exists: Show Image
              if (state.capturedImage != null) ...[
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(state.capturedImage!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Action Area based on state
              if (state.capturedImage != null) ...[
                if (state.isAnalyzing)
                  _buildLoadingIndicator()
                else if (state.identifiedResult != null)
                  _buildResultCard(
                    state, 
                    viewModel,
                    onNewCapture: () {
                      viewModel.retake();
                      _pickImage();
                    },
                  )
                else
                  _buildReviewControls(viewModel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraBackground extends StatelessWidget {
  const _CameraBackground();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  const Color(0xFFE8F4F8),
                  const Color(0xFFD4E8EF),
                  const Color(0xFFC0DCE5),
                ]
              : [
                  const Color(0xFF0F2027),
                  const Color(0xFF203A43),
                  const Color(0xFF2C5364),
                ],
        ),
      ),
    );
  }
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motherLang = ref.watch(motherLanguageProvider);
    final appLang = ref.watch(appLanguageProvider);
    final currentWeight = ref.watch(fontWeightProvider);
    final isLightMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    final config = ref.watch(appConfigProvider);

    return AlertDialog(
      title: Text(locale.settings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${locale.motherLanguage}:'),
          const SizedBox(height: 8),
          _buildLanguageDropdown(
            value: motherLang,
            onChanged: (val) => ref.read(motherLanguageProvider.notifier).setLanguage(val!),
          ),
          const SizedBox(height: 16),
          Text('${locale.appLanguage}:'),
          const SizedBox(height: 8),
          _buildAppLanguageDropdown(
            value: appLang,
            onChanged: (val) => ref.read(appLanguageProvider.notifier).setLanguage(val!),
          ),
          const SizedBox(height: 16),
          Text('${locale.fontWeightLabel}:'),
          const SizedBox(height: 8),
          _buildWeightSelector(ref, currentWeight),
          const SizedBox(height: 16),
          Text('${locale.themeLabel}:'),
          const SizedBox(height: 8),
          _buildThemeSelector(ref, isLightMode),
          if (config.showResetOnboarding) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildResetButton(context, ref, locale),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(locale.close),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown({required String value, required ValueChanged<String?> onChanged}) {
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      items: LanguageConfig.supportedLanguages.map((lang) {
        return DropdownMenuItem(
          value: lang.name,
          child: Row(
            children: [
              Text(lang.flag),
              const SizedBox(width: 8),
              Text(lang.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAppLanguageDropdown({required String value, required ValueChanged<String?> onChanged}) {
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      items: ['English', 'Thai'].map((lang) {
        final langData = LanguageConfig.supportedLanguages.firstWhere((l) => l.name == lang);
        return DropdownMenuItem(
          value: lang,
          child: Row(
            children: [
              Text(langData.flag),
              const SizedBox(width: 8),
              Text(lang),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildWeightSelector(WidgetRef ref, int currentWeight) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 200, label: Text('200')),
        ButtonSegment(value: 500, label: Text('500')),
        ButtonSegment(value: 700, label: Text('700')),
      ],
      selected: {currentWeight},
      showSelectedIcon: false,
      onSelectionChanged: (newSelection) {
        ref.read(fontWeightProvider.notifier).setWeight(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(ref.context).colorScheme.primaryContainer;
          }
          return Theme.of(ref.context).colorScheme.surfaceContainerHighest;
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }

  Widget _buildThemeSelector(WidgetRef ref, bool isLightMode) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
        ButtonSegment(value: true, label: Text('Light'), icon: Icon(Icons.light_mode)),
      ],
      selected: {isLightMode},
      showSelectedIcon: false,
      onSelectionChanged: (newSelection) {
        ref.read(themeModeProvider.notifier).setLightMode(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(ref.context).colorScheme.primaryContainer;
          }
          return Theme.of(ref.context).colorScheme.surfaceContainerHighest;
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }


  Widget _buildResetButton(BuildContext context, WidgetRef ref, AppLocale locale) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await ref.read(settingsServiceProvider).resetFirstTime();
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        },
        icon: const Icon(Icons.refresh, color: Colors.redAccent),
        label: Text(locale.resetOnboarding, style: const TextStyle(color: Colors.redAccent)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
