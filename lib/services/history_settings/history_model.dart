import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
// history_model.dart

part 'history_model.freezed.dart';
part 'history_model.g.dart';

@freezed
abstract class HistoryModel with _$HistoryModel {
  const factory HistoryModel({@Default([]) List<LiveRoom> historyRooms, @Default(50) int historyLimit}) =
      _HistoryModel;

  factory HistoryModel.fromJson(Map<String, dynamic> json) => _$HistoryModelFromJson(json);
}
