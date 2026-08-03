import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Semi-transparent pill tag overlay used on destination cards.
class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tagOverlay,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant, color: Colors.white, size: 9),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
