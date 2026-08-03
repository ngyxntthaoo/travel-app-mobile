import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../services/file_service.dart';
import '../theme/app_colors.dart';

/// Offline document attachment UI — shows filename + open/attach/remove controls.
/// Shared between TripChecklistScreen and TripAccomsScreen.
class AttachmentRow extends StatelessWidget {
  const AttachmentRow({
    super.key,
    required this.localFilePath,
    required this.onAttach,
    this.onRemove,
    this.attachLabel = 'Attach File',
    this.openLabel = 'Open Offline',
  });

  final String? localFilePath;
  final VoidCallback onAttach;
  final VoidCallback? onRemove;
  final String attachLabel;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    final hasAttachment = localFilePath != null;
    final fileName = hasAttachment ? p.basename(localFilePath!) : '';

    return Row(
      children: [
        Icon(
          hasAttachment ? Icons.attach_file_rounded : Icons.add_to_photos_outlined,
          size: 15,
          color: hasAttachment ? AppColors.teal : Colors.grey,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: hasAttachment
              ? InkWell(
                  onTap: () => FileService.instance.openDocument(localFilePath!),
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: AppColors.teal,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  'No file attached',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
        if (hasAttachment) ...[
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => FileService.instance.openDocument(localFilePath!),
            icon: const Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.teal),
            label: Text(openLabel, style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.bold)),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.cancel, size: 16, color: Colors.redAccent),
              onPressed: onRemove,
            ),
          ],
        ] else
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAttach,
            icon: const Icon(Icons.upload_file_rounded, size: 14, color: AppColors.teal),
            label: Text(attachLabel, style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
