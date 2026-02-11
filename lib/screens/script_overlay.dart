import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:async';

class ScriptOverlay extends StatefulWidget {
  const ScriptOverlay({super.key});

  @override
  State<ScriptOverlay> createState() => _ScriptOverlayState();
}

class _ScriptOverlayState extends State<ScriptOverlay> {
  String _script = "Loading script...";
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isScrolling = false;
  double _scrollSpeed = 2.0;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    // Listen for data sent from the main app
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is String) {
        setState(() {
          _script = event;
        });
      } else if (event is Map) {
        // Handle other events if needed
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleScrolling() {
    if (_isScrolling) {
      _scrollTimer?.cancel();
      setState(() {
        _isScrolling = false;
      });
    } else {
      if (_script.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Header / Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () async {
                    await FlutterOverlayWindow.closeOverlay();
                  },
                ),
                Expanded(
                  child: Container(
                    height: 30,
                    color: Colors.transparent,
                    child: const Icon(Icons.drag_handle, color: Colors.white54),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isScrolling ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _toggleScrolling,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 1),
            // Script Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _script,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _fontSize,
                      height: 1.5,
                      shadows: const [
                        Shadow(blurRadius: 2, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Resize Handle (Bottom Right)
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onPanUpdate: (details) async {
                  await FlutterOverlayWindow.resizeOverlay(
                    (details.delta.dx * 2).toInt(),
                    (details.delta.dy * 2).toInt(),
                    false,
                  );
                  // Note: resizeOverlay implementation varies, dragging corner usually simpler
                  // For now, let's keep it simple or allow resizing via standard window method if supported
                  // flutter_overlay_window typically handles resize via flags
                },
                child: const Icon(
                  Icons.photo_size_select_small,
                  color: Colors.white54,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
