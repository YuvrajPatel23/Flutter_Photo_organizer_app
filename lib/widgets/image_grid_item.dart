import 'dart:io';
import 'package:flutter/material.dart';

class ImageGridItem extends StatelessWidget {
  final File file;
  final bool isVideo;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ImageGridItem({
    super.key,
    required this.file,
    required this.isVideo,
    required this.isFavorite,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: Colors.blueAccent, width: 3) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: isVideo
                ? const Icon(Icons.videocam, size: 40)
                : Image.file(file, fit: BoxFit.cover),
          ),
          if (isFavorite)
            const Positioned(top: 4, right: 4, child: Icon(Icons.star, color: Colors.orange)),
        ],
      ),
    );
  }
}
