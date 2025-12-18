import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_view_model.dart';

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
  
  final List<String> _languages = [
    'English',
    'Spanish',
    'Japanese',
    'French',
    'German',
    'Italian',
    'Chinese',
    'Korean',
    'Russian',
    'Portuguese',
  ];

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
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
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: _languages.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                viewModel.setTargetLanguage(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControl(CameraViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: GestureDetector(
        onTap: () => viewModel.capture(_controller!),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white24,
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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
          ElevatedButton.icon(
            onPressed: viewModel.retake,
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: viewModel.identify,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Identify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8), // Space for close button
              Text(
                language.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subject,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: viewModel.speakResult,
                    icon: const Icon(Icons.volume_up_rounded),
                    iconSize: 32,
                    color: Colors.blueAccent,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onNewCapture ?? viewModel.retake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('New Capture'),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: viewModel.resetResultOnly,
            ),
          ),
        ],
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
