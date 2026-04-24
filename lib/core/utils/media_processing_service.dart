import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:palette_generator/palette_generator.dart';

class MediaProcessingService {
  /// Compresses an image to <= targetSizeKB (default 200KB).
  /// Caps the long edge at maxEdgePx (default 1024). Returns null if the
  /// target cannot be met even at minimum quality.
  static Future<Uint8List?> compressImage(
    XFile file, {
    int targetSizeKB = 200,
    int maxEdgePx = 1024,
  }) =>
      compressImagePath(file.path, targetSizeKB: targetSizeKB, maxEdgePx: maxEdgePx);

  static Future<Uint8List?> compressImagePath(
    String filePath, {
    int targetSizeKB = 200,
    int maxEdgePx = 1024,
  }) async {
    int quality = 90;
    Uint8List? last;

    while (quality >= 20) {
      final result = await FlutterImageCompress.compressWithFile(
        filePath,
        // Cap the long edge; flutter_image_compress keeps aspect ratio and
        // only scales DOWN when the source exceeds these bounds.
        minWidth: maxEdgePx,
        minHeight: maxEdgePx,
        quality: quality,
        keepExif: false,
      );
      if (result == null) return null;
      last = result;

      final sizeKB = result.lengthInBytes / 1024;
      debugPrint('compressImage quality=$quality size=${sizeKB.toStringAsFixed(1)}KB');
      if (sizeKB <= targetSizeKB) return result;

      quality -= 10;
    }
    // Couldn't hit the budget — return null so the caller can surface a clear error
    // instead of silently uploading an oversized image.
    return (last != null && last.lengthInBytes <= targetSizeKB * 1024) ? last : null;
  }

  /// Extracts a dominant color hex. Returns null on failure so callers can
  /// distinguish "no color found" from a real grey.
  static Future<String?> extractDominantColor(Uint8List imageBytes) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(imageBytes),
        maximumColorCount: 5,
      );
      final dominant = palette.dominantColor?.color;
      if (dominant == null) return null;
      final argb = dominant.toARGB32();
      return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    } catch (e) {
      debugPrint('Color extraction failed: $e');
      return null;
    }
  }
}
