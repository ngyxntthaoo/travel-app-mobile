import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Teal snackbar used for "feature coming soon" messages.
void showComingSoon(BuildContext context, String featureName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$featureName coming soon!'),
      backgroundColor: AppColors.teal,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Floating white pill snackbar with a green checkmark.
void showSuccessToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 24, left: 60, right: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    ),
  );
}
