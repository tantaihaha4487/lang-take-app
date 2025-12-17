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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Check if running on Linux (camera plugin has limited Linux support)
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
        // No cameras available
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

    // Show fallback UI when camera is not supported (e.g., on Linux)
    if (_cameraNotSupported) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      onPressed: cameraState.isAnalyzing ? null : _pickImage,
                      icon: cameraState.isAnalyzing 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(cameraState.isAnalyzing ? 'Analyzing...' : 'Pick from Gallery'),
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
              // Show captured image and result if available
              if (cameraState.capturedImage != null) ...[
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(cameraState.capturedImage!, fit: BoxFit.cover),
                  ),
                ),
              ],
              if (cameraState.resultText != null && cameraState.resultText!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    cameraState.resultText!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    ref.read(cameraViewModelProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text('Analyze Another', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Still loading camera
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
          if (cameraState.capturedImage != null)
            Image.memory(cameraState.capturedImage!, fit: BoxFit.cover)
          else
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapUp: _onTapUp,
              child: CameraPreview(_controller!),
            ),
            
          // Result Overlay
            
          // Result Overlay
          if (cameraState.resultText != null && cameraState.resultText!.isNotEmpty)
             Positioned(
               bottom: 100,
               left: 20,
               right: 20,
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.7),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: SingleChildScrollView(
                   child: Text(
                     cameraState.resultText!,
                     style: const TextStyle(color: Colors.white, fontSize: 16),
                   ),
                 ),
               ),
             ),

          // Capture Button
          if (cameraState.capturedImage == null)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: () {
                  ref.read(cameraViewModelProvider.notifier).captureAndAnalyze(_controller!);
                },
                backgroundColor: Colors.white,
                child: cameraState.isAnalyzing 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(color: Colors.black),
                    ) 
                  : const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ),
          
          // Reset Button
          if (cameraState.capturedImage != null && !cameraState.isAnalyzing)
             Positioned(
               top: 40,
               left: 20,
               child: IconButton(
                 icon: const Icon(Icons.close, color: Colors.white, size: 30),
                 onPressed: () {
                   ref.read(cameraViewModelProvider.notifier).reset();
                 },
               ),
             ),
        ],
      ),
    );
  }
}
