import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
// `InputImage` is re-exported by the subject_segmentation package.
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartstyle/features/intake/domain/segmenter.dart';

class MlKitSegmenter implements Segmenter {
  final SubjectSegmenter _segmenter = SubjectSegmenter(
    options: SubjectSegmenterOptions(
      enableForegroundConfidenceMask: true,
      enableForegroundBitmap: true,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false,
      ),
    ),
  );

  @override
  Future<Uint8List?> stripBackground(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/seg_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);

      final input = InputImage.fromFilePath(file.path);
      final result = await _segmenter.processImage(input);

      final fg = result.foregroundBitmap;
      if (fg == null) {
        debugPrint('MlKitSegmenter: no foreground bitmap produced');
        return null;
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      return _encodePng(fg, w, h);
    } catch (e, st) {
      debugPrint('MlKitSegmenter failure: $e\n$st');
      return null;
    }
  }

  Future<Uint8List?> _encodePng(Uint8List rgba, int width, int height) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final pngData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return pngData?.buffer.asUint8List();
  }

  @override
  Future<void> dispose() => _segmenter.close();
}
