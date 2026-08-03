import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tappable search bar field used on HomeScreen and DestinationScreen.
class SearchBarField extends StatelessWidget {
  const SearchBarField({
    super.key,
    required this.hintText,
    this.onTap,
  });

  final String hintText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textHint, size: 20),
            const SizedBox(width: 10),
            Text(
              hintText,
              style: const TextStyle(color: AppColors.textHint, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
