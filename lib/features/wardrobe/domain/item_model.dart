import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

enum ItemState {
  @JsonValue('clean') clean,
  @JsonValue('worn') worn,
  @JsonValue('laundry') laundry,
}

@freezed
abstract class ItemModel with _$ItemModel {
  const factory ItemModel({
    @JsonKey(name: 'item_id') required String itemId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'ml_detected_category') String? mlDetectedCategory,
    required String category,
    @JsonKey(name: 'primary_hex') required String primaryHex,
    @JsonKey(name: 'warmth_clo') @Default(0.0) double warmthClo,
    @JsonKey(name: 'purchase_price') double? purchasePrice,
    @Default([]) List<String> occasions,
    @Default([]) List<String> fabrics,
    @JsonKey(name: 'times_worn') @Default(0) int timesWorn,
    @Default(ItemState.clean) ItemState state,
    @JsonKey(name: 'wears_before_laundry') @Default(1) int wearsBeforeLaundry,
    @JsonKey(name: 'last_worn_at') DateTime? lastWornAt,
    @JsonKey(name: 'cost_per_wear') double? costPerWear,
  }) = _ItemModel;

  factory ItemModel.fromJson(Map<String, dynamic> json) => _$ItemModelFromJson(json);
}
