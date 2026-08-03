import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  static final FileService instance = FileService._init();
  FileService._init();

  /// Picks an image or PDF file from the device.
  /// Copies the file to the local application storage directory.
  /// Returns the absolute path of the local file copy.
  Future<String?> pickAndSaveDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // User canceled
      }

      final sourceFile = File(result.files.single.path!);
      final appDocDir = await getApplicationDocumentsDirectory();
      
      // Ensure the storage directory exists
      if (!await appDocDir.exists()) {
        await appDocDir.create(recursive: true);
      }
      
      // Generate a unique file name to avoid overwriting existing documents
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourceFile.path)}';
      final destinationPath = p.join(appDocDir.path, fileName);
      
      // Copy file to local app storage directory
      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error picking or saving file: $e');
      return null;
    }
  }

  /// Opens the document at the given local path.
  Future<void> openDocument(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        final result = await OpenFilex.open(localPath);
        if (result.type != ResultType.done) {
          debugPrint('Failed to open file: ${result.message}');
        }
      } else {
        debugPrint('File does not exist at path: $localPath');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }
}
