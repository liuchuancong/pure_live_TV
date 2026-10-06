import 'package:media_core_danmaku/media_core_danmaku.dart';
import 'package:pure_live/core/models/live_message/live_message_model.dart';

/// Bridges the app's [LiveMessage] model to media_core_danmaku's
/// [DanmakuMessage]: the gate / repeated / similarity filters live in the
/// package and speak the package type, the site transports speak the app's.
DanmakuMessage normalizeLiveMessage(LiveMessage message) {
  return DanmakuMessage(
    type: switch (message.type) {
      LiveMessageType.chat => DanmakuMessageType.chat,
      LiveMessageType.gift => DanmakuMessageType.gift,
      _ => DanmakuMessageType.system,
    },
    userName: message.userName,
    text: message.message,
    color: DanmakuColor(message.color.r, message.color.g, message.color.b),
    userId: message.userId ?? '',
    isLocal: message.isLocal,
    messageId: message.messageId ?? '',
    sentAt: message.sentAt,
  );
}
