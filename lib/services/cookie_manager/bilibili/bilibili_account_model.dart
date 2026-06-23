import 'package:freezed_annotation/freezed_annotation.dart';
// bilibili_account_model.dart

part 'bilibili_account_model.freezed.dart';
part 'bilibili_account_model.g.dart';

@freezed
abstract class BilibiliAccountModel with _$BilibiliAccountModel {
  const factory BilibiliAccountModel({@Default(false) bool isLogined, @Default('') String name, @Default(0) int uid}) =
      _BilibiliAccountModel;

  factory BilibiliAccountModel.fromJson(Map<String, dynamic> json) => _$BilibiliAccountModelFromJson(json);
}
