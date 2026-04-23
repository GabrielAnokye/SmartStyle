// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemModel _$ItemModelFromJson(Map<String, dynamic> json) => _ItemModel(
  itemId: json['item_id'] as String,
  userId: json['user_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  imageUrl: json['image_url'] as String,
  mlDetectedCategory: json['ml_detected_category'] as String?,
  category: json['category'] as String,
  primaryHex: json['primary_hex'] as String,
  warmthClo: (json['warmth_clo'] as num?)?.toDouble() ?? 0.0,
  purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
  occasions:
      (json['occasions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  fabrics:
      (json['fabrics'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  timesWorn: (json['times_worn'] as num?)?.toInt() ?? 0,
  state:
      $enumDecodeNullable(_$ItemStateEnumMap, json['state']) ?? ItemState.clean,
  wearsBeforeLaundry: (json['wears_before_laundry'] as num?)?.toInt() ?? 1,
  lastWornAt: json['last_worn_at'] == null
      ? null
      : DateTime.parse(json['last_worn_at'] as String),
  costPerWear: (json['cost_per_wear'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ItemModelToJson(_ItemModel instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
      'image_url': instance.imageUrl,
      'ml_detected_category': instance.mlDetectedCategory,
      'category': instance.category,
      'primary_hex': instance.primaryHex,
      'warmth_clo': instance.warmthClo,
      'purchase_price': instance.purchasePrice,
      'occasions': instance.occasions,
      'fabrics': instance.fabrics,
      'times_worn': instance.timesWorn,
      'state': _$ItemStateEnumMap[instance.state]!,
      'wears_before_laundry': instance.wearsBeforeLaundry,
      'last_worn_at': instance.lastWornAt?.toIso8601String(),
      'cost_per_wear': instance.costPerWear,
    };

const _$ItemStateEnumMap = {
  ItemState.clean: 'clean',
  ItemState.worn: 'worn',
  ItemState.laundry: 'laundry',
};
