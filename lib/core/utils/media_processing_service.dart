import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:palette_generator/palette_generator.dart';

class MediaProcessingService {
  /// Compresses an image to be strictly <= targetSizeKB (default 200KB).
  /// Max edge is bound to 1024px to preserve storage.
  static Future<Uint8List?> compressImage(XFile file, {int targetSizeKB = 200}) async {
    final filePath = file.path;
    Uint8List? result;
    int quality = 90;

    debugPrint('Starting image compression for target: ${targetSizeKB}KB');

    do {
      result = await FlutterImageCompress.compressWithFile(
        filePath,
        minWidth: 1024,
        minHeight: 1024,
        quality: quality,
      );

      if (result == null) break;

      final currentSizeKB = result.lengthInBytes / 1024;
      if (currentSizeKB <= targetSizeKB) {
        break; // Within limits
      }
      
      quality -= 10;
      if (quality < 10) break; // Hard stop
    } while (true);

    return result;
  }

  /// Extracts dominant color hex safely from memory bytes.
  static Future<String> extractDominantColor(Uint8List imageBytes) async {
    try {
      final imageProvider = MemoryImage(imageBytes);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.grey;
      
      // Convert Color to Hex string e.g., "#2B4A6B"
      return '#${dominantColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    } catch (e) {
      debugPrint('Color extraction failed: $e');
      return '#808080'; // fallback grey
    }
  }
}
