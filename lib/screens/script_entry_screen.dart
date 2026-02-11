import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:io';
import 'teleprompter_screen.dart';

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
      appBar: AppBar(title: const Text('Script Viewer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _scriptController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your script here...',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_scriptController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeleprompterScreen(script: _scriptController.text),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a script first'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Start Recording',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (Platform.isAndroid)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    if (_scriptController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a script first'),
                        ),
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

                    // Share script content via listener mechanism in overlay
                    // Note: 'overlayContent' param in showOverlay might be enough or
                    // we might need shareData if the valid param is not String
                    await FlutterOverlayWindow.shareData(
                      _scriptController.text,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Start System Overlay (Android)',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
