import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const CategoryChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? Colors.orange.shade100 : Colors.grey.shade200,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: selected ? Colors.deepOrange : Colors.black87,
        ),
      ),
    );
  }
}
