import 'dart:io';

class MediaItem {
  final File file;
  final String folder;
  final bool isVideo;
  bool isFavorite;
  bool isSelected;

  MediaItem({
    required this.file,
    required this.folder,
    this.isVideo = false,
    this.isFavorite = false,
    this.isSelected = false,
  });
}
