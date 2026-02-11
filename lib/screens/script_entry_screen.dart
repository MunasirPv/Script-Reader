import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'teleprompter_screen.dart';
import 'recordings_list_screen.dart';

class ScriptEntryScreen extends StatefulWidget {
  const ScriptEntryScreen({super.key});

  @override
  State<ScriptEntryScreen> createState() => _ScriptEntryScreenState();
}

class _ScriptEntryScreenState extends State<ScriptEntryScreen> {
  final TextEditingController _scriptController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Script Viewer'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Your Script",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _scriptController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Paste or type your script here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_scriptController.text.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeleprompterScreen(
                              script: _scriptController.text,
                            ),
                          ),
                        );
                      } else {
                        Fluttertoast.showToast(
                          msg: "Please enter a script first",
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordingsListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  if (_scriptController.text.isEmpty) {
                    Fluttertoast.showToast(
                      msg: "Please enter a script first",
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                    return;
                  }

                  bool status =
                      await FlutterOverlayWindow.isPermissionGranted();
                  if (!status) {
                    bool? granted =
                        await FlutterOverlayWindow.requestPermission();
                    if (granted != true) {
                      return;
                    }
                  }

                  if (await FlutterOverlayWindow.isActive()) {
                    await FlutterOverlayWindow.closeOverlay();
                  }

                  await FlutterOverlayWindow.showOverlay(
                    enableDrag: true,
                    overlayTitle: "Script Viewer",
                    overlayContent: _scriptController.text,
                    flag: OverlayFlag.defaultFlag,
                    visibility: NotificationVisibility.visibilityPublic,
                    positionGravity: PositionGravity.auto,
                    height: 600,
                    width: WindowSize.matchParent,
                  );
                },
                icon: const Icon(Icons.layers),
                label: const Text('Launch Overlay (AndroidOnly)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.tealAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.tealAccent,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
