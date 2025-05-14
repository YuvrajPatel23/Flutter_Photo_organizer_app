import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'folder_detail_page.dart';
import '../models/media_item.dart';
import '../main.dart';

class GalleryHomePage extends StatefulWidget {
  const GalleryHomePage({super.key});

  @override
  State<GalleryHomePage> createState() => _GalleryHomePageState();
}

class _GalleryHomePageState extends State<GalleryHomePage> {
  List<String> folders = ['Favorites', 'All'];
  List<MediaItem> mediaItems = [];
  String searchQuery = '';
  Set<String> selectedFolders = {};

  @override
  void initState() {
    super.initState();
    _clearOldMedia().then((_) => _loadMediaItems());
  }

  Future<void> _clearOldMedia() async {
    final dir = await getApplicationDocumentsDirectory();
    final directory = Directory(dir.path);
    if (directory.existsSync()) {
      final files = directory.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          final path = file.path.toLowerCase();
          if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.mp4')) {
            file.deleteSync();
          }
        }
      }
    }
  }

  Future<void> _loadMediaItems() async {
    final dir = await getApplicationDocumentsDirectory();
    final entries = dir.listSync(recursive: true);
    final Set<String> folderSet = {'Favorites', 'All'};
    final List<MediaItem> allItems = [];

    for (var entry in entries) {
      if (entry is File) {
        final path = entry.path;
        final isVideo = path.toLowerCase().endsWith('.mp4');
        final isImage = path.toLowerCase().endsWith('.jpg') ||
            path.toLowerCase().endsWith('.jpeg') ||
            path.toLowerCase().endsWith('.png');

        if (!isVideo && !isImage) continue;

        final segments = path.split(Platform.pathSeparator);
        if (segments.length < 2) continue;

        final folderName = segments[segments.length - 2];

        const excludedFolders = [
          'Documents',
          'flutter_assets',
          'picked_images',
          'data',
          'lib',
          'cache',
          'tmp',
          '__MACOSX'
        ];

        if (excludedFolders.contains(folderName.toLowerCase())) continue;

        allItems.add(MediaItem(
          file: entry,
          folder: folderName,
          isVideo: isVideo,
        ));
        folderSet.add(folderName);
      }
    }

    setState(() {
      mediaItems = allItems;
      folders = folderSet.toList();
    });
  }



  void _createFolder(String name) {
    if (!folders.contains(name)) {
      setState(() => folders.add(name));
    }
  }

  void _deleteSelectedFolders() {
    if (selectedFolders.isEmpty) return;

    if (selectedFolders.contains("All") || selectedFolders.contains("Favorites")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete system folders")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Folder(s)"),
        content: Text(
          "Delete ${selectedFolders.length} folders and their items?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                mediaItems.removeWhere((m) => selectedFolders.contains(m.folder));
                folders.removeWhere((f) => selectedFolders.contains(f));
                selectedFolders.clear();
              });
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool get isSelectionMode => selectedFolders.isNotEmpty;

  void _exitSelectionMode() {
    if (isSelectionMode) {
      setState(() => selectedFolders.clear());
    }
  }

  bool isDarkMode() => themeNotifier.value == ThemeMode.dark;

  Widget buildThemeToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          themeNotifier.value = isDarkMode() ? ThemeMode.light : ThemeMode.dark;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDarkMode() ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode() ? Colors.white : Colors.black,
            width: 2.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: isDarkMode() ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDarkMode() ? Colors.white : Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  List<String> get filteredFolders {
    return folders
        .where((folder) => folder.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Future<Widget> _buildFolderThumbnail(MediaItem item) async {
    if (item.isVideo) {
      final controller = VideoPlayerController.file(item.file);
      await controller.initialize();
      controller.setVolume(0);
      controller.pause();
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      return Image.file(item.file, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _exitSelectionMode,
      child: Scaffold(
        appBar: AppBar(
          title: isSelectionMode
              ? Text("${selectedFolders.length} selected")
              : const Text("My Photo Organizer"),
          actions: [
            if (isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedFolders,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: buildThemeToggle(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search folders...",
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
        ),
        body: filteredFolders.isEmpty
            ? const Center(child: Text("No folders found"))
            : GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredFolders.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final folderName = filteredFolders[index];
            final isSelected = selectedFolders.contains(folderName);
            final itemsInFolder = folderName == 'All'
                ? mediaItems
                : folderName == 'Favorites'
                ? mediaItems.where((m) => m.isFavorite).toList()
                : mediaItems.where((m) => m.folder == folderName).toList();
            final firstItem = itemsInFolder.isNotEmpty ? itemsInFolder.first : null;

            return GestureDetector(
              onTap: () {
                if (isSelectionMode) {
                  setState(() {
                    isSelected
                        ? selectedFolders.remove(folderName)
                        : selectedFolders.add(folderName);
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FolderDetailPage(
                        folderName: folderName,
                        items: mediaItems,
                        onAdd: (item) => setState(() => mediaItems.add(item)),
                        onDelete: (item) => setState(() => mediaItems.remove(item)),
                        onFavoriteToggle: (item) => setState(() => item.isFavorite = !item.isFavorite),
                      ),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (folderName != 'All' && folderName != 'Favorites') {
                  setState(() => selectedFolders.add(folderName));
                }
              },
              child: Stack(
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (folderName == 'All')
                          const Center(child: Icon(Icons.grid_view, size: 50, color: Colors.orange))
                        else if (folderName == 'Favorites')
                          const Center(child: Icon(Icons.star, size: 50, color: Colors.orange))
                        else if (firstItem != null)
                            FutureBuilder<Widget>(
                              future: _buildFolderThumbnail(firstItem),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done &&
                                    snapshot.hasData) {
                                  return snapshot.data!;
                                } else {
                                  return const Center(child: CircularProgressIndicator());
                                }
                              },
                            )
                          else
                            const Center(child: Icon(Icons.folder, size: 50, color: Colors.orange)),

                        Container(
                          color: Colors.black.withOpacity(0.4),
                          alignment: Alignment.center,
                          child: Text(
                            folderName,
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.check_circle, size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: isSelectionMode
            ? null
            : FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) {
                final controller = TextEditingController();
                return AlertDialog(
                  title: const Text("Create Folder"),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: "Enter folder name"),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isNotEmpty &&
                            !folders.contains(name) &&
                            name != 'All' &&
                            name != 'Favorites') {
                          _createFolder(name);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Create"),
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.create_new_folder),
        ),
      ),
    );
  }
}
