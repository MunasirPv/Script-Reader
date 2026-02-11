import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:typed_data';
import 'video_player_screen.dart'; // Import the player screen

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  List<FileSystemEntity> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final directory = await getApplicationDocumentsDirectory();
    final String recordingsPath = '${directory.path}/Recordings';
    final dir = Directory(recordingsPath);

    if (await dir.exists()) {
      setState(() {
        _videos =
            dir.listSync().where((item) => item.path.endsWith('.mp4')).toList()
              ..sort(
                (a, b) =>
                    b.statSync().modified.compareTo(a.statSync().modified),
              ); // Sort by date desc
        _isLoading = false;
      });
    } else {
      setState(() {
        _videos = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVideo(FileSystemEntity file) async {
    try {
      await file.delete();
      _loadVideos(); // Refresh list
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Video deleted",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error deleting video: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Recordings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final file = _videos[index];
                final String fileName = file.uri.pathSegments.last;
                final DateTime modified = file.statSync().modified;
                final String dateStr =
                    "${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFF2C2C2C),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerScreen(videoPath: file.path),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 80,
                              height: 60,
                              child: FutureBuilder<Uint8List?>(
                                future: VideoThumbnail.thumbnailData(
                                  video: file.path,
                                  imageFormat: ImageFormat.JPEG,
                                  maxWidth:
                                      160, // doubled for better quality on high DPI
                                  quality: 50,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.data != null) {
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        ),
                                        const Center(
                                          child: Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white70,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return Container(
                                    color: Colors.black26,
                                    child: const Icon(
                                      Icons.video_file,
                                      color: Colors.white24,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteVideo(file),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
