import 'package:flutter/material.dart';

/// Shared delete-confirmation dialog used across all trip sub-screens.
/// Returns [true] if the user confirmed, [false] or [null] if cancelled.
Future<bool> showDeleteConfirmation({
  required BuildContext context,
  required String title,
  String content = 'This action cannot be undone.',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(content, style: const TextStyle(color: Colors.black54)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
