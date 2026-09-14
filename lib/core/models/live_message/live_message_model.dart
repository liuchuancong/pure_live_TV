import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_message_model.freezed.dart';
part 'live_message_model.g.dart';

enum LiveMessageType { chat, gift, online, superChat }

/// 弹幕显示位置。
enum LiveMessagePlacement { top, bottom, scroll }

/// 观众人数更新的指标类型（弹幕在线人数推送）。
enum LiveAudienceMetricKind { onlineViewers, popularity, totalViewers }

/// 弹幕人数更新负载，挂在 LiveMessage.online 消息的 data 上。
class LiveAudienceUpdate {
  const LiveAudienceUpdate({required this.kind, required this.value});
  final LiveAudienceMetricKind kind;
  final int value;
}

/// 弹幕渲染样式（字号/描边/位置），由站点适配器按平台礼物或会员消息填充。
class LiveMessageStyle {
  const LiveMessageStyle({
    this.placement,
    this.fontSize,
    this.fontWeight = 400,
    this.fontFamily,
    this.showStroke,
    this.strokeColor = 0xFF000000,
    this.strokeWidth,
  });

  final LiveMessagePlacement? placement;
  final double? fontSize;
  final int fontWeight;
  final String? fontFamily;
  final bool? showStroke;
  final int strokeColor;
  final double? strokeWidth;
}

@freezed
abstract class LiveMessageColor with _$LiveMessageColor {
  const LiveMessageColor._();
  const factory LiveMessageColor({required int r, required int g, required int b}) = _LiveMessageColor;

  factory LiveMessageColor.fromJson(Map<String, dynamic> json) => _$LiveMessageColorFromJson(json);

  static LiveMessageColor get white => const LiveMessageColor(r: 255, g: 255, b: 255);

  static LiveMessageColor numberToColor(int intColor) {
    String hex = intColor.toRadixString(16).padLeft(6, '0');
    if (hex.length > 6) hex = hex.substring(hex.length - 6);
    return LiveMessageColor(
      r: int.parse(hex.substring(0, 2), radix: 16),
      g: int.parse(hex.substring(2, 4), radix: 16),
      b: int.parse(hex.substring(4, 6), radix: 16),
    );
  }

  static LiveMessageColor fromType(int type) {
    const Map<int, LiveMessageColor> colorMap = {
      1: LiveMessageColor(r: 255, g: 0, b: 0),
      2: LiveMessageColor(r: 30, g: 135, b: 240),
      3: LiveMessageColor(r: 122, g: 200, b: 75),
      4: LiveMessageColor(r: 255, g: 127, b: 0),
      5: LiveMessageColor(r: 155, g: 57, b: 244),
      6: LiveMessageColor(r: 255, g: 105, b: 180),
    };
    return colorMap[type] ?? LiveMessageColor.white;
  }

  @override
  String toString() =>
      "#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}";
}

@freezed
abstract class LiveMessage with _$LiveMessage {
  const factory LiveMessage({
    required LiveMessageType type,
    required String userName,
    required String message,
    required LiveMessageColor color,
    dynamic data,
    String? messageId,
    String? userId,
    DateTime? sentAt,
    @Default(false) bool isLocal,
    LiveMessageStyle? style,
  }) = _LiveMessage;

  factory LiveMessage.fromJson(Map<String, dynamic> json) => _$LiveMessageFromJson(json);
}

@freezed
abstract class LiveSuperChatMessage with _$LiveSuperChatMessage {
  const factory LiveSuperChatMessage({
    required String userName,
    required String face,
    required String message,
    required int price,
    required DateTime startTime,
    required DateTime endTime,
    required String backgroundColor,
    required String backgroundBottomColor,
  }) = _LiveSuperChatMessage;

  factory LiveSuperChatMessage.fromJson(Map<String, dynamic> json) => _$LiveSuperChatMessageFromJson(json);
}
