import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import 'package:file_picker/file_picker.dart';

class FolderDetailPage extends StatefulWidget {
  final String folderName;
  final List<MediaItem> items;
  final Function(MediaItem) onAdd;
  final Function(MediaItem) onDelete;
  final Function(MediaItem) onFavoriteToggle;

  const FolderDetailPage({
    super.key,
    required this.folderName,
    required this.items,
    required this.onAdd,
    required this.onDelete,
    required this.onFavoriteToggle,
  });

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  final ImagePicker _picker = ImagePicker();
  String sortMode = 'date';
  bool selectionMode = false;
  final Set<MediaItem> selectedItems = {};
  List<MediaItem> folderItems = [];

  @override
  void initState() {
    super.initState();
    _refreshFolderItems();
  }

  void _refreshFolderItems() {
    setState(() {
      if (widget.folderName == 'Favorites') {
        folderItems = widget.items.where((m) => m.isFavorite).toList();
      } else if (widget.folderName == 'All') {
        folderItems = widget.items;
      } else {
        folderItems = widget.items.where((m) => m.folder == widget.folderName).toList();
      }

      if (sortMode == 'name') {
        folderItems.sort((a, b) =>
            a.file.path.split('/').last.compareTo(b.file.path.split('/').last));
      } else {
        folderItems.sort((a, b) =>
            b.file.lastModifiedSync().compareTo(a.file.lastModifiedSync()));
      }
    });
  }

  Future<void> _pickMedia({bool isVideo = false}) async {
    List<File> selectedFiles = [];

    if (isVideo) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );
      if (result != null) {
        selectedFiles = result.paths.map((path) => File(path!)).toList();
      }
    } else {
      final images = await _picker.pickMultiImage();
      if (images != null) {
        selectedFiles = images.map((img) => File(img.path)).toList();
      }
    }

    if (selectedFiles.isEmpty) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Uploading files..."),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final folderPath = '${dir.path}/${widget.folderName}';
    final folderDir = Directory(folderPath);
    if (!folderDir.existsSync()) folderDir.createSync(recursive: true);

    int addedCount = 0;

    for (File pickedFile in selectedFiles) {
      final pickedBytes = await pickedFile.readAsBytes();

      final alreadyExists = widget.items.any((item) =>
      item.folder == widget.folderName &&
          item.isVideo == isVideo &&
          item.file.existsSync() &&
          item.file.readAsBytesSync().toString() == pickedBytes.toString());

      if (alreadyExists) continue;

      final ext = isVideo ? '.mp4' : '.jpg';
      final newFile = await pickedFile.copy(
          '$folderPath/${DateTime.now().millisecondsSinceEpoch}$ext');

      final media = MediaItem(
        file: newFile,
        folder: widget.folderName,
        isVideo: isVideo,
      );

      widget.onAdd(media);
      addedCount++;
    }

    // Hide progress
    Navigator.pop(context);

    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploaded $addedCount file(s) successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No new files were added")),
      );
    }

    _refreshFolderItems();
  }



  void _toggleSelection(MediaItem item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
        if (selectedItems.isEmpty) selectionMode = false;
      } else {
        selectedItems.add(item);
        selectionMode = true;
      }
    });
  }

  void _deleteSelected() {
    for (final item in selectedItems) {
      widget.onDelete(item);
    }
    selectedItems.clear();
    selectionMode = false;
    _refreshFolderItems();
  }

  void _exitSelectionMode() {
    if (selectionMode) {
      setState(() {
        selectedItems.clear();
        selectionMode = false;
      });
    }
  }

  Future<Widget> _buildThumbnail(MediaItem item) async {
    if (item.isVideo) {
      final controller = VideoPlayerController.file(item.file);
      await controller.initialize();
      controller.setVolume(0);
      controller.pause();

      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 50),
          ),
        ],
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(item.file, fit: BoxFit.cover),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _exitSelectionMode,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.folderName),
          actions: [
            if (selectionMode)
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: _deleteSelected,
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                sortMode = value;
                _refreshFolderItems();
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'date', child: Text('Sort by Date')),
                PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              ],
              icon: const Icon(Icons.sort),
            ),
          ],
        ),
        body: folderItems.isEmpty
            ? const Center(child: Text("No items found"))
            : GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: folderItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = folderItems[index];
            final isSelected = selectedItems.contains(item);

            return FutureBuilder<Widget>(
              future: _buildThumbnail(item),
              builder: (context, snapshot) {
                final thumbnail = snapshot.data;

                return GestureDetector(
                  onTap: () {
                    if (selectionMode) {
                      _toggleSelection(item);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaPreviewPage(
                            items: folderItems,
                            initialIndex: index,
                            onToggleFavorite: (item) {
                              setState(() {
                                item.isFavorite = !item.isFavorite;
                              });
                              widget.onFavoriteToggle(item);
                              _refreshFolderItems();
                            },
                          ),
                        ),
                      );
                    }
                  },
                  onLongPress: () => _toggleSelection(item),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: thumbnail ?? const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: IconButton(
                          icon: Icon(
                            Icons.star,
                            color: item.isFavorite ? Colors.orange : Colors.white70,
                          ),
                          onPressed: () {
                            widget.onFavoriteToggle(item);
                            _refreshFolderItems();
                          },
                        ),
                      ),
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.check_circle, size: 40, color: Colors.lightBlue),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: (!selectionMode &&
            widget.folderName != 'Favorites' &&
            widget.folderName != 'All')
            ? PopupMenuButton<String>(
          icon: const Icon(Icons.add),
          onSelected: (value) {
            if (value == 'photo') _pickMedia(isVideo: false);
            if (value == 'video') _pickMedia(isVideo: true);
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'photo', child: Text('Add Photo')),
            PopupMenuItem(value: 'video', child: Text('Add Video')),
          ],
        )
            : null,
      ),
    );
  }
}


// 👇 PREVIEW PAGE

class MediaPreviewPage extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;
  final Function(MediaItem) onToggleFavorite;

  const MediaPreviewPage({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onToggleFavorite,
  });

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  late PageController _controller;
  late int _currentIndex;
  bool showMetadata = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  String _formatFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMMd().add_jm().format(date);
  }

  Widget _buildMetadata(MediaItem item) {
    final file = item.file;
    final folderPath = item.folder;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text("📄 File Name: ${file.path.split('/').last}", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text("📁 Folder Path: $folderPath", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text("🕒 Last Modified: ${_formatDate(file.lastModifiedSync())}", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text("📦 Size: ${_formatFileSize(file)}", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text("📸 Type: ${item.isVideo ? 'Video' : 'Image'}", style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              widget.items[_currentIndex].isFavorite ? Icons.star : Icons.star_border,
              color: widget.items[_currentIndex].isFavorite ? Colors.orange : Colors.white,
            ),
            onPressed: () {
              setState(() {
                widget.items[_currentIndex].isFavorite =
                !widget.items[_currentIndex].isFavorite;
              });
              widget.onToggleFavorite(widget.items[_currentIndex]);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (showMetadata) setState(() => showMetadata = false);
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! < -10) {
                setState(() => showMetadata = true);
              } else if (details.primaryDelta! > 10) {
                Navigator.pop(context);
              }
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  showMetadata = false;
                });
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Center(
                  child: item.isVideo
                      ? VideoPlayerScreen(file: item.file)
                      : Image.file(item.file),
                );
              },
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: showMetadata ? 0 : -220,
            left: 0,
            right: 0,
            child: _buildMetadata(widget.items[_currentIndex]),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({required this.file});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(Duration d) =>
      "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_controller.value.isInitialized)
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: VideoPlayer(_controller),
            ),
          )
        else
          const CircularProgressIndicator(),

        VideoProgressIndicator(_controller, allowScrubbing: true),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_5, color: Colors.white),
              onPressed: () {
                final pos = _controller.value.position - const Duration(seconds: 5);
                _controller.seekTo(pos > Duration.zero ? pos : Duration.zero);
              },
            ),
            IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 36,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_5, color: Colors.white),
              onPressed: () {
                final max = _controller.value.duration;
                final pos = _controller.value.position + const Duration(seconds: 5);
                _controller.seekTo(pos < max ? pos : max);
              },
            ),
            const SizedBox(width: 20),
            const Text("Vol", style: TextStyle(color: Colors.white)),
            Slider(
              value: _volume,
              onChanged: (v) {
                setState(() {
                  _volume = v;
                  _controller.setVolume(_volume);
                });
              },
              min: 0,
              max: 1,
              activeColor: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
}
