import 'dart:typed_data';

/// In-memory draft of an item being intaken via the batch flow.
/// Byte payloads live on disk; this holds only paths + metadata.
class IntakeDraft {
  final String id;
  final String rawImagePath;
  String? segmentedImagePath;
  String? suggestedCategory;
  double? confidence;
  String? primaryHex;
  double? purchasePrice;
  String? userCategory;
  DateTime displayedAt;
  DateTime? savedAt;

  IntakeDraft({
    required this.id,
    required this.rawImagePath,
    this.segmentedImagePath,
    this.suggestedCategory,
    this.confidence,
    this.primaryHex,
    this.purchasePrice,
    this.userCategory,
    DateTime? displayedAt,
  }) : displayedAt = displayedAt ?? DateTime.now();

  String get effectiveCategory =>
      (userCategory?.trim().isNotEmpty ?? false)
          ? userCategory!.trim()
          : (suggestedCategory ?? 'uncategorized');

  int? get timeToConfirmMs =>
      savedAt?.difference(displayedAt).inMilliseconds;

  /// Bytes are loaded lazily by the caller; expose a typed alias.
  static Future<Uint8List> noopLoad(String _) async => Uint8List(0);
}
