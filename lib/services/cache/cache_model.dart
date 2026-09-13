import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_model.freezed.dart';
part 'cache_model.g.dart';

@freezed
abstract class CacheModel with _$CacheModel {
  const factory CacheModel({
    @Default(0.0) double cacheSizeMB,
    @Default(0.0) double refreshTurns,
    @Default(0) int imageCacheEpoch,
    @Default(false) bool isScanning,
    @Default(false) bool isClearing,
    @Default(false) bool isRefreshingImages,
  }) = _CacheModel;

  factory CacheModel.fromJson(Map<String, dynamic> json) => _$CacheModelFromJson(json);
}
