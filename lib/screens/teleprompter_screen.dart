import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'recordings_list_screen.dart';

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
  bool _isPaused = false;

  // Teleprompter State
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isScrolling = false;
  double _scrollSpeed = 2.0; // Pixels per tick (approx 60Hz)
  double _fontSize = 24.0;
  bool _showSettings = true;
  String? _lastVideoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadLatestVideo();
  }

  Future<void> _loadLatestVideo() async {
    final directory = await getApplicationDocumentsDirectory();
    final String recordingsPath = '${directory.path}/Recordings';
    final dir = Directory(recordingsPath);
    if (await dir.exists()) {
      final List<FileSystemEntity> files =
          dir.listSync().where((item) => item.path.endsWith('.mp4')).toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );

      if (files.isNotEmpty) {
        setState(() {
          _lastVideoPath = files.first.path;
        });
      }
    }
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
      if (mounted) {}
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
          Fluttertoast.showToast(
            msg: "No camera found",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error initializing camera: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
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

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    // Get current lens direction
    final lensDirection = _controller!.description.lensDirection;
    CameraDescription newCamera;

    if (lensDirection == CameraLensDirection.front) {
      newCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
    } else {
      newCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
    }

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error switching camera: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    if (_controller == null || !_isRecording) return;
    try {
      await _controller!.pauseVideoRecording();
      setState(() {
        _isPaused = true;
        // Optional: pause scrolling too?
        if (_isScrolling) _toggleScrolling();
      });
    } on CameraException catch (e) {
      Fluttertoast.showToast(
        msg: "Error pausing recording: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _resumeRecording() async {
    if (_controller == null || !_isRecording) return;
    try {
      await _controller!.resumeVideoRecording();
      setState(() {
        _isPaused = false;
        // Optional: resume scrolling too?
        if (!_isScrolling) _toggleScrolling();
      });
    } on CameraException catch (e) {
      Fluttertoast.showToast(
        msg: "Error resuming recording: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
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
      Fluttertoast.showToast(
        msg: "Error starting recording: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      XFile file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        if (_isScrolling)
          _toggleScrolling(); // Stop scrolling when recording stops
      });

      // Save to Application Documents Directory for In-App Gallery
      final directory = await getApplicationDocumentsDirectory();
      final String recordingsPath = '${directory.path}/Recordings';
      await Directory(recordingsPath).create(recursive: true);

      final String fileName =
          'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String newPath = '$recordingsPath/$fileName';

      await File(file.path).copy(newPath);

      // Update latest video path for thumbnail
      _loadLatestVideo();

      // Save to gallery using Gal on the NEW path (or old one, doesn't matter much but new one is safer)
      // Gal.putVideo(newPath);
      // The user says "The recorded video is not displaying the gallery". Let's try explicit save.
      try {
        await Gal.putVideo(newPath);
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Video saved to gallery and in-app storage",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        debugPrint("Gallery save error: $e");
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Saved locally, but gallery save failed: $e",
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error stopping recording: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
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
                      // Controls Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isRecording &&
                              _cameras != null &&
                              _cameras!.length > 1)
                            FloatingActionButton(
                              heroTag: "switch",
                              mini: true,
                              onPressed: _switchCamera,
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.switch_camera,
                                color: Colors.black,
                              ),
                            ),
                          const SizedBox(width: 20),
                          FloatingActionButton(
                            heroTag: "record",
                            onPressed: () {
                              if (_isRecording) {
                                if (_isPaused) {
                                  _resumeRecording();
                                } else {
                                  _pauseRecording();
                                }
                              } else {
                                _startRecording();
                              }
                            },
                            backgroundColor: _isRecording
                                ? (_isPaused ? Colors.orange : Colors.white)
                                : Colors.red,
                            child: Icon(
                              _isRecording
                                  ? (_isPaused ? Icons.play_arrow : Icons.pause)
                                  : Icons.videocam,
                              color: _isRecording
                                  ? (_isPaused ? Colors.white : Colors.red)
                                  : Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          if (_isRecording)
                            FloatingActionButton(
                              heroTag: "stop",
                              mini: true,
                              onPressed: _stopRecording,
                              backgroundColor: Colors.red,
                              child: const Icon(
                                Icons.stop,
                                color: Colors.white,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RecordingsListScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[800],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: _lastVideoPath != null
                                    ? const Icon(
                                        Icons.video_library,
                                        color: Colors.white,
                                      )
                                    : const Icon(
                                        Icons.photo_library,
                                        color: Colors.white54,
                                      ),
                              ),
                            ),
                        ],
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
