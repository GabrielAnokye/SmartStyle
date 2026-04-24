import 'dart:typed_data';

/// Strips non-subject pixels from clothing photos.
/// Implementations may run on-device (ML Kit) or remotely.
abstract class Segmenter {
  /// Returns PNG bytes with transparent background, or null if segmentation failed.
  Future<Uint8List?> stripBackground(Uint8List bytes);

  Future<void> dispose();
}
