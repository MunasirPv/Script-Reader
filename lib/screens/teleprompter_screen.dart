import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'dart:async';

class TeleprompterScreen extends StatefulWidget {
  final String script;

  const TeleprompterScreen({super.key, required this.script});

  @override
  State<TeleprompterScreen> createState() => _TeleprompterScreenState();
}

class _TeleprompterScreenState extends State<TeleprompterScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;

  // Teleprompter State
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isScrolling = false;
  double _scrollSpeed = 2.0; // Pixels per tick (approx 60Hz)
  double _fontSize = 24.0;
  bool _showSettings = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos, // For saving to gallery
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and Microphone permissions are required'),
          ),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the front camera by default if available
        CameraDescription camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: true,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No camera found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _toggleScrolling() {
    if (_isScrolling) {
      _scrollTimer?.cancel();
      setState(() {
        _isScrolling = false;
      });
    } else {
      setState(() {
        _isScrolling = true;
      });
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) return;

      double newOffset = _scrollController.offset + _scrollSpeed;
      if (newOffset >= _scrollController.position.maxScrollExtent) {
        _scrollTimer?.cancel();
        setState(() {
          _isScrolling = false;
        });
      } else {
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        // Auto-start scrolling when recording starts if not already scrolling?
        // Let's keep it manual for now or user preference.
        // User script request says "load the script and it will display the script overlay"
        // Common behavior: start scrolling on record is nice.
        if (!_isScrolling) _toggleScrolling();
      });
    } on CameraException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      XFile file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        if (_isScrolling)
          _toggleScrolling(); // Stop scrolling when recording stops
      });

      // Save to gallery
      await Gal.putVideo(file.path);
      bool saved = true; // Gal throws if it fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved == true ? 'Video saved to gallery' : 'Failed to save video',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording or saving: $e')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Script Overlay
          SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                color: Colors
                    .transparent, // Allow taps to pass through for showing settings, but capture for scroll?
                // Actually if I put color transparent, gestures working.
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        top: 200,
                        bottom: 300,
                      ), // Start with padding
                      child: Text(
                        widget.script,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _fontSize,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Settings Panel & Controls
          if (_showSettings)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.all(16.0),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sliders Row
                      Row(
                        children: [
                          const Icon(Icons.text_fields, color: Colors.white),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: 16.0,
                              max: 48.0,
                              onChanged: (value) {
                                setState(() {
                                  _fontSize = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.speed, color: Colors.white),
                          Expanded(
                            child: Slider(
                              value: _scrollSpeed,
                              min: 0.5,
                              max: 10.0,
                              onChanged: (value) {
                                setState(() {
                                  _scrollSpeed = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Record Button
                      FloatingActionButton(
                        onPressed: _toggleRecording,
                        backgroundColor: _isRecording
                            ? Colors.red
                            : Colors.white,
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          color: _isRecording ? Colors.white : Colors.red,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Play/Pause Scroll Button (Floating if settings hidden or integrated?)
          // Let's add a small play/pause button for scrolling separate from recording
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: Icon(
                _isScrolling
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
                size: 40,
              ),
              onPressed: _toggleScrolling,
            ),
          ),
        ],
      ),
    );
  }
}
