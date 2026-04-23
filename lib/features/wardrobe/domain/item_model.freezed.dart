// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemModel {

@JsonKey(name: 'item_id') String get itemId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'image_url') String get imageUrl;@JsonKey(name: 'ml_detected_category') String? get mlDetectedCategory; String get category;@JsonKey(name: 'primary_hex') String get primaryHex;@JsonKey(name: 'warmth_clo') double get warmthClo;@JsonKey(name: 'purchase_price') double? get purchasePrice; List<String> get occasions; List<String> get fabrics;@JsonKey(name: 'times_worn') int get timesWorn; ItemState get state;@JsonKey(name: 'wears_before_laundry') int get wearsBeforeLaundry;@JsonKey(name: 'last_worn_at') DateTime? get lastWornAt;@JsonKey(name: 'cost_per_wear') double? get costPerWear;
/// Create a copy of ItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemModelCopyWith<ItemModel> get copyWith => _$ItemModelCopyWithImpl<ItemModel>(this as ItemModel, _$identity);

  /// Serializes this ItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemModel&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mlDetectedCategory, mlDetectedCategory) || other.mlDetectedCategory == mlDetectedCategory)&&(identical(other.category, category) || other.category == category)&&(identical(other.primaryHex, primaryHex) || other.primaryHex == primaryHex)&&(identical(other.warmthClo, warmthClo) || other.warmthClo == warmthClo)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&const DeepCollectionEquality().equals(other.occasions, occasions)&&const DeepCollectionEquality().equals(other.fabrics, fabrics)&&(identical(other.timesWorn, timesWorn) || other.timesWorn == timesWorn)&&(identical(other.state, state) || other.state == state)&&(identical(other.wearsBeforeLaundry, wearsBeforeLaundry) || other.wearsBeforeLaundry == wearsBeforeLaundry)&&(identical(other.lastWornAt, lastWornAt) || other.lastWornAt == lastWornAt)&&(identical(other.costPerWear, costPerWear) || other.costPerWear == costPerWear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,userId,createdAt,imageUrl,mlDetectedCategory,category,primaryHex,warmthClo,purchasePrice,const DeepCollectionEquality().hash(occasions),const DeepCollectionEquality().hash(fabrics),timesWorn,state,wearsBeforeLaundry,lastWornAt,costPerWear);

@override
String toString() {
  return 'ItemModel(itemId: $itemId, userId: $userId, createdAt: $createdAt, imageUrl: $imageUrl, mlDetectedCategory: $mlDetectedCategory, category: $category, primaryHex: $primaryHex, warmthClo: $warmthClo, purchasePrice: $purchasePrice, occasions: $occasions, fabrics: $fabrics, timesWorn: $timesWorn, state: $state, wearsBeforeLaundry: $wearsBeforeLaundry, lastWornAt: $lastWornAt, costPerWear: $costPerWear)';
}


}

/// @nodoc
abstract mixin class $ItemModelCopyWith<$Res>  {
  factory $ItemModelCopyWith(ItemModel value, $Res Function(ItemModel) _then) = _$ItemModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'item_id') String itemId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'ml_detected_category') String? mlDetectedCategory, String category,@JsonKey(name: 'primary_hex') String primaryHex,@JsonKey(name: 'warmth_clo') double warmthClo,@JsonKey(name: 'purchase_price') double? purchasePrice, List<String> occasions, List<String> fabrics,@JsonKey(name: 'times_worn') int timesWorn, ItemState state,@JsonKey(name: 'wears_before_laundry') int wearsBeforeLaundry,@JsonKey(name: 'last_worn_at') DateTime? lastWornAt,@JsonKey(name: 'cost_per_wear') double? costPerWear
});




}
/// @nodoc
class _$ItemModelCopyWithImpl<$Res>
    implements $ItemModelCopyWith<$Res> {
  _$ItemModelCopyWithImpl(this._self, this._then);

  final ItemModel _self;
  final $Res Function(ItemModel) _then;

/// Create a copy of ItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? userId = null,Object? createdAt = null,Object? imageUrl = null,Object? mlDetectedCategory = freezed,Object? category = null,Object? primaryHex = null,Object? warmthClo = null,Object? purchasePrice = freezed,Object? occasions = null,Object? fabrics = null,Object? timesWorn = null,Object? state = null,Object? wearsBeforeLaundry = null,Object? lastWornAt = freezed,Object? costPerWear = freezed,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,mlDetectedCategory: freezed == mlDetectedCategory ? _self.mlDetectedCategory : mlDetectedCategory // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,primaryHex: null == primaryHex ? _self.primaryHex : primaryHex // ignore: cast_nullable_to_non_nullable
as String,warmthClo: null == warmthClo ? _self.warmthClo : warmthClo // ignore: cast_nullable_to_non_nullable
as double,purchasePrice: freezed == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double?,occasions: null == occasions ? _self.occasions : occasions // ignore: cast_nullable_to_non_nullable
as List<String>,fabrics: null == fabrics ? _self.fabrics : fabrics // ignore: cast_nullable_to_non_nullable
as List<String>,timesWorn: null == timesWorn ? _self.timesWorn : timesWorn // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ItemState,wearsBeforeLaundry: null == wearsBeforeLaundry ? _self.wearsBeforeLaundry : wearsBeforeLaundry // ignore: cast_nullable_to_non_nullable
as int,lastWornAt: freezed == lastWornAt ? _self.lastWornAt : lastWornAt // ignore: cast_nullable_to_non_nullable
as DateTime?,costPerWear: freezed == costPerWear ? _self.costPerWear : costPerWear // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemModel].
extension ItemModelPatterns on ItemModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemModel value)  $default,){
final _that = this;
switch (_that) {
case _ItemModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _ItemModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'item_id')  String itemId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'ml_detected_category')  String? mlDetectedCategory,  String category, @JsonKey(name: 'primary_hex')  String primaryHex, @JsonKey(name: 'warmth_clo')  double warmthClo, @JsonKey(name: 'purchase_price')  double? purchasePrice,  List<String> occasions,  List<String> fabrics, @JsonKey(name: 'times_worn')  int timesWorn,  ItemState state, @JsonKey(name: 'wears_before_laundry')  int wearsBeforeLaundry, @JsonKey(name: 'last_worn_at')  DateTime? lastWornAt, @JsonKey(name: 'cost_per_wear')  double? costPerWear)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemModel() when $default != null:
return $default(_that.itemId,_that.userId,_that.createdAt,_that.imageUrl,_that.mlDetectedCategory,_that.category,_that.primaryHex,_that.warmthClo,_that.purchasePrice,_that.occasions,_that.fabrics,_that.timesWorn,_that.state,_that.wearsBeforeLaundry,_that.lastWornAt,_that.costPerWear);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'item_id')  String itemId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'ml_detected_category')  String? mlDetectedCategory,  String category, @JsonKey(name: 'primary_hex')  String primaryHex, @JsonKey(name: 'warmth_clo')  double warmthClo, @JsonKey(name: 'purchase_price')  double? purchasePrice,  List<String> occasions,  List<String> fabrics, @JsonKey(name: 'times_worn')  int timesWorn,  ItemState state, @JsonKey(name: 'wears_before_laundry')  int wearsBeforeLaundry, @JsonKey(name: 'last_worn_at')  DateTime? lastWornAt, @JsonKey(name: 'cost_per_wear')  double? costPerWear)  $default,) {final _that = this;
switch (_that) {
case _ItemModel():
return $default(_that.itemId,_that.userId,_that.createdAt,_that.imageUrl,_that.mlDetectedCategory,_that.category,_that.primaryHex,_that.warmthClo,_that.purchasePrice,_that.occasions,_that.fabrics,_that.timesWorn,_that.state,_that.wearsBeforeLaundry,_that.lastWornAt,_that.costPerWear);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'item_id')  String itemId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'ml_detected_category')  String? mlDetectedCategory,  String category, @JsonKey(name: 'primary_hex')  String primaryHex, @JsonKey(name: 'warmth_clo')  double warmthClo, @JsonKey(name: 'purchase_price')  double? purchasePrice,  List<String> occasions,  List<String> fabrics, @JsonKey(name: 'times_worn')  int timesWorn,  ItemState state, @JsonKey(name: 'wears_before_laundry')  int wearsBeforeLaundry, @JsonKey(name: 'last_worn_at')  DateTime? lastWornAt, @JsonKey(name: 'cost_per_wear')  double? costPerWear)?  $default,) {final _that = this;
switch (_that) {
case _ItemModel() when $default != null:
return $default(_that.itemId,_that.userId,_that.createdAt,_that.imageUrl,_that.mlDetectedCategory,_that.category,_that.primaryHex,_that.warmthClo,_that.purchasePrice,_that.occasions,_that.fabrics,_that.timesWorn,_that.state,_that.wearsBeforeLaundry,_that.lastWornAt,_that.costPerWear);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemModel implements ItemModel {
  const _ItemModel({@JsonKey(name: 'item_id') required this.itemId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'image_url') required this.imageUrl, @JsonKey(name: 'ml_detected_category') this.mlDetectedCategory, required this.category, @JsonKey(name: 'primary_hex') required this.primaryHex, @JsonKey(name: 'warmth_clo') this.warmthClo = 0.0, @JsonKey(name: 'purchase_price') this.purchasePrice, final  List<String> occasions = const [], final  List<String> fabrics = const [], @JsonKey(name: 'times_worn') this.timesWorn = 0, this.state = ItemState.clean, @JsonKey(name: 'wears_before_laundry') this.wearsBeforeLaundry = 1, @JsonKey(name: 'last_worn_at') this.lastWornAt, @JsonKey(name: 'cost_per_wear') this.costPerWear}): _occasions = occasions,_fabrics = fabrics;
  factory _ItemModel.fromJson(Map<String, dynamic> json) => _$ItemModelFromJson(json);

@override@JsonKey(name: 'item_id') final  String itemId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'image_url') final  String imageUrl;
@override@JsonKey(name: 'ml_detected_category') final  String? mlDetectedCategory;
@override final  String category;
@override@JsonKey(name: 'primary_hex') final  String primaryHex;
@override@JsonKey(name: 'warmth_clo') final  double warmthClo;
@override@JsonKey(name: 'purchase_price') final  double? purchasePrice;
 final  List<String> _occasions;
@override@JsonKey() List<String> get occasions {
  if (_occasions is EqualUnmodifiableListView) return _occasions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_occasions);
}

 final  List<String> _fabrics;
@override@JsonKey() List<String> get fabrics {
  if (_fabrics is EqualUnmodifiableListView) return _fabrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fabrics);
}

@override@JsonKey(name: 'times_worn') final  int timesWorn;
@override@JsonKey() final  ItemState state;
@override@JsonKey(name: 'wears_before_laundry') final  int wearsBeforeLaundry;
@override@JsonKey(name: 'last_worn_at') final  DateTime? lastWornAt;
@override@JsonKey(name: 'cost_per_wear') final  double? costPerWear;

/// Create a copy of ItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemModelCopyWith<_ItemModel> get copyWith => __$ItemModelCopyWithImpl<_ItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemModel&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mlDetectedCategory, mlDetectedCategory) || other.mlDetectedCategory == mlDetectedCategory)&&(identical(other.category, category) || other.category == category)&&(identical(other.primaryHex, primaryHex) || other.primaryHex == primaryHex)&&(identical(other.warmthClo, warmthClo) || other.warmthClo == warmthClo)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&const DeepCollectionEquality().equals(other._occasions, _occasions)&&const DeepCollectionEquality().equals(other._fabrics, _fabrics)&&(identical(other.timesWorn, timesWorn) || other.timesWorn == timesWorn)&&(identical(other.state, state) || other.state == state)&&(identical(other.wearsBeforeLaundry, wearsBeforeLaundry) || other.wearsBeforeLaundry == wearsBeforeLaundry)&&(identical(other.lastWornAt, lastWornAt) || other.lastWornAt == lastWornAt)&&(identical(other.costPerWear, costPerWear) || other.costPerWear == costPerWear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,userId,createdAt,imageUrl,mlDetectedCategory,category,primaryHex,warmthClo,purchasePrice,const DeepCollectionEquality().hash(_occasions),const DeepCollectionEquality().hash(_fabrics),timesWorn,state,wearsBeforeLaundry,lastWornAt,costPerWear);

@override
String toString() {
  return 'ItemModel(itemId: $itemId, userId: $userId, createdAt: $createdAt, imageUrl: $imageUrl, mlDetectedCategory: $mlDetectedCategory, category: $category, primaryHex: $primaryHex, warmthClo: $warmthClo, purchasePrice: $purchasePrice, occasions: $occasions, fabrics: $fabrics, timesWorn: $timesWorn, state: $state, wearsBeforeLaundry: $wearsBeforeLaundry, lastWornAt: $lastWornAt, costPerWear: $costPerWear)';
}


}

/// @nodoc
abstract mixin class _$ItemModelCopyWith<$Res> implements $ItemModelCopyWith<$Res> {
  factory _$ItemModelCopyWith(_ItemModel value, $Res Function(_ItemModel) _then) = __$ItemModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'item_id') String itemId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'ml_detected_category') String? mlDetectedCategory, String category,@JsonKey(name: 'primary_hex') String primaryHex,@JsonKey(name: 'warmth_clo') double warmthClo,@JsonKey(name: 'purchase_price') double? purchasePrice, List<String> occasions, List<String> fabrics,@JsonKey(name: 'times_worn') int timesWorn, ItemState state,@JsonKey(name: 'wears_before_laundry') int wearsBeforeLaundry,@JsonKey(name: 'last_worn_at') DateTime? lastWornAt,@JsonKey(name: 'cost_per_wear') double? costPerWear
});




}
/// @nodoc
class __$ItemModelCopyWithImpl<$Res>
    implements _$ItemModelCopyWith<$Res> {
  __$ItemModelCopyWithImpl(this._self, this._then);

  final _ItemModel _self;
  final $Res Function(_ItemModel) _then;

/// Create a copy of ItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? userId = null,Object? createdAt = null,Object? imageUrl = null,Object? mlDetectedCategory = freezed,Object? category = null,Object? primaryHex = null,Object? warmthClo = null,Object? purchasePrice = freezed,Object? occasions = null,Object? fabrics = null,Object? timesWorn = null,Object? state = null,Object? wearsBeforeLaundry = null,Object? lastWornAt = freezed,Object? costPerWear = freezed,}) {
  return _then(_ItemModel(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,mlDetectedCategory: freezed == mlDetectedCategory ? _self.mlDetectedCategory : mlDetectedCategory // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,primaryHex: null == primaryHex ? _self.primaryHex : primaryHex // ignore: cast_nullable_to_non_nullable
as String,warmthClo: null == warmthClo ? _self.warmthClo : warmthClo // ignore: cast_nullable_to_non_nullable
as double,purchasePrice: freezed == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double?,occasions: null == occasions ? _self._occasions : occasions // ignore: cast_nullable_to_non_nullable
as List<String>,fabrics: null == fabrics ? _self._fabrics : fabrics // ignore: cast_nullable_to_non_nullable
as List<String>,timesWorn: null == timesWorn ? _self.timesWorn : timesWorn // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ItemState,wearsBeforeLaundry: null == wearsBeforeLaundry ? _self.wearsBeforeLaundry : wearsBeforeLaundry // ignore: cast_nullable_to_non_nullable
as int,lastWornAt: freezed == lastWornAt ? _self.lastWornAt : lastWornAt // ignore: cast_nullable_to_non_nullable
as DateTime?,costPerWear: freezed == costPerWear ? _self.costPerWear : costPerWear // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
