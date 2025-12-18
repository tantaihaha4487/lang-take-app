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
  
  final List<String> _languages = LanguageConfig.names;


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
          // Layer 0: Background Gradient (to make glass pop)
          Container(
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
          ),
          
          // Layer 1: Camera Preview or Captured Image
          if (cameraState.isReviewing && cameraState.capturedImage != null)
            Image.memory(cameraState.capturedImage!, fit: BoxFit.cover)
          else
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapUp: _onTapUp,
              child: CameraPreview(_controller!),
            ),
          
          // Layer 2: UI Overlays
          SafeArea(
            child: Column(
              children: [
                // Top Bar: Language Selector
                _buildTopBar(cameraState, viewModel),
                
                const Spacer(),
                
                // Bottom Area: Controls or Results
                if (cameraState.isAnalyzing)
                  _buildLoadingIndicator()
                else if (cameraState.identifiedResult != null)
                  _buildResultCard(cameraState, viewModel)
                else if (cameraState.isReviewing)
                  _buildReviewControls(viewModel)
                else
                  _buildCaptureControl(viewModel),
              ],
            ),
          ),

          
          // Error Message Toast
          if (cameraState.errorMessage != null)
            Positioned(
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
                  cameraState.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(CameraState state, CameraViewModel viewModel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'I want to learn: ',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              DropdownButton<String>(
                value: state.targetLanguage,
                dropdownColor: Colors.black.withOpacity(0.8),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                underline: Container(),
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
        ),
      ),
    );
  }


  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final motherLang = ref.watch(motherLanguageProvider);
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Mother Language:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: motherLang,
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
                        ref.read(motherLanguageProvider.notifier).setLanguage(newValue);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildCaptureControl(CameraViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: GestureDetector(
        onTap: () => viewModel.capture(_controller!),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
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
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildReviewControls(CameraViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGlassButton(
            onPressed: viewModel.retake,
            icon: Icons.refresh,
            label: 'Retake',
            isPrimary: false,
          ),
          _buildGlassButton(
            onPressed: () {
              final motherLang = ref.read(motherLanguageProvider);
              viewModel.identify(motherLang);
            },
            icon: Icons.auto_awesome,
            label: 'Identify',
            isPrimary: true,
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
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isPrimary ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: isPrimary ? Colors.black : Colors.white),
            label: Text(label, style: TextStyle(color: isPrimary ? Colors.black : Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Analyzing...',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(CameraState state, CameraViewModel viewModel, {VoidCallback? onNewCapture}) {
    final result = state.identifiedResult;
    if (result == null) return const SizedBox.shrink();

    final subject = result['subject'] ?? 'Unknown';
    final language = result['language'] ?? state.targetLanguage;

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
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (result['translation'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        result['translation'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGlassIconButton(
                          onPressed: viewModel.speakResult,
                          icon: Icons.volume_up_rounded,
                        ),
                        const SizedBox(width: 20),
                        _buildGlassButton(
                          onPressed: onNewCapture ?? viewModel.retake,
                          icon: Icons.add_a_photo_outlined,
                          label: 'New Capture',
                          isPrimary: true,
                        ),
                      ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            iconSize: 28,
          ),
        ),
      ),
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
