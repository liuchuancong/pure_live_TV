import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'package:pure_live/shared/common/index.dart';
import 'package:pure_live/shared/models/live_message/live_message_model.dart';
import 'package:pure_live/shared/contracts/live_danmaku.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class DouyuDanmaku implements LiveDanmaku {
  DouyuDanmaku({bool Function()? filterSuspectedAutomatedMessages})
    : _filterSuspectedAutomatedMessages = filterSuspectedAutomatedMessages ?? (() => false);

  // ignore: unused_field
  final bool Function() _filterSuspectedAutomatedMessages;

  @override
  int heartbeatTime = 45 * 1000;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  void markConnected() {
    _connected = true;
  }

  @override
  void markDisconnected() {
    _connected = false;
  }

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onReconnect;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;
  String serverUrl = "wss://danmuproxy.douyu.com:8506";

  WebSocketUtils? webScoketUtils;
  // ignore: unused_field
  String _roomId = '';
  int _generation = 0;

  @visibleForTesting
  void debugSetRoomId(String roomId) => _roomId = roomId;

  @override
  Future start(dynamic args) async {
    final generation = ++_generation;
    await webScoketUtils?.close();
    webScoketUtils = null;
    if (generation != _generation) return;
    _roomId = args.toString();
    markDisconnected();
    webScoketUtils = WebSocketUtils(
      url: serverUrl,
      heartBeatTime: heartbeatTime,
      onMessage: (e) {
        if (generation == _generation) decodeMessage(e);
      },
      onReady: () {
        if (generation != _generation) return;
        markConnected();
        onReady?.call();
        joinRoom(args);
      },
      onHeartBeat: () {
        heartbeat();
      },
      onReconnect: () {
        if (generation != _generation) return;
        markDisconnected();
        onReconnect?.call(i18n('danmaku_reconnecting'));
      },
      onClose: (e) {
        if (generation != _generation) return;
        markDisconnected();
        onClose?.call('${i18n('danmaku_connect_failed')}: $e');
      },
    );
    await webScoketUtils?.connect();
  }

  void joinRoom(dynamic roomId) {
    webScoketUtils?.sendMessage(serializeDouyu("type@=loginreq/roomid@=$roomId/"));
    webScoketUtils?.sendMessage(serializeDouyu("type@=joingroup/rid@=$roomId/gid@=-9999/"));
  }

  @override
  void heartbeat() {
    var data = serializeDouyu("type@=mrkl/");
    webScoketUtils?.sendMessage(data);
  }

  @override
  Future stop() async {
    _generation++;
    markDisconnected();
    onMessage = null;
    onReconnect = null;
    onClose = null;
    onReady = null;
    await webScoketUtils?.close();
    webScoketUtils = null;
  }

  void decodeMessage(List<int> data) {
    try {
      String? result = deserializeDouyu(data);
      if (result == null) {
        return;
      }
      var jsonData = sttToJObject(result);

      var type = jsonData["type"]?.toString();
      var fans = jsonData["if"] ?? '0'.toString();
      LiveMessage? liveMsg;
      if (type == "chatmsg" && fans == '1') {
        var col = int.tryParse(jsonData["col"].toString()) ?? 0;
        liveMsg = LiveMessage(
          type: LiveMessageType.chat,
          userName: jsonData["nn"].toString(),
          message: jsonData["txt"].toString(),
          color: getColor(col),
        );
      } else if (type == "comm_chatmsg") {
        DateTime curTimestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(jsonData["now"]));
        var face = "";
        try {
          face = jsonData["chatmsg"]["ic"];
        } catch (e) {
          CoreLog.error("DouyuSuperChat-face:$e");
        }
        LiveSuperChatMessage sc = LiveSuperChatMessage(
          backgroundBottomColor: "#292a60",
          backgroundColor: "#c1c1ff",
          endTime: curTimestamp.add(Duration(seconds: int.parse(jsonData["cet"]))),
          face: "https://apic.douyucdn.cn/upload/${face}_small.jpg",
          message: jsonData["chatmsg"]["txt"].toString(),
          price: int.parse(jsonData["cprice"]) ~/ 100,
          startTime: curTimestamp,
          userName: jsonData["chatmsg"]["nn"].toString(),
        );
        liveMsg = LiveMessage(
          type: LiveMessageType.superChat,
          userName: "SUPER_CHAT_MESSAGE",
          message: "SUPER_CHAT_MESSAGE",
          color: LiveMessageColor.white,
          data: sc,
        );
      } else if (type == "voice_trlt") {
        var scData = jsonData["list"][0];
        LiveSuperChatMessage sc2 = LiveSuperChatMessage(
          backgroundBottomColor: "#246488",
          backgroundColor: "#ffffff",
          endTime: DateTime.fromMillisecondsSinceEpoch(int.parse(scData["etime"]) * 1000),
          face: "https://${scData["uat"][1]}",
          message: scData["content"].toString(),
          price: int.parse(scData["realPrice"]) ~/ 100,
          startTime: DateTime.fromMillisecondsSinceEpoch(int.parse(scData["acptime"]) * 1000),
          userName: scData["un"].toString(),
        );
        liveMsg = LiveMessage(
          type: LiveMessageType.superChat,
          userName: "SUPER_CHAT_MESSAGE",
          message: "SUPER_CHAT_MESSAGE",
          color: LiveMessageColor.white,
          data: sc2,
        );
      }
      if (liveMsg != null) {
        onMessage?.call(liveMsg);
      }
    } catch (e) {
      CoreLog.error("DouyuSuperChat:$e");
    }
  }

  List<int> serializeDouyu(String body) {
    try {
      const int clientSendToServer = 689;
      const int encrypted = 0;
      const int reserved = 0;

      List<int> buffer = utf8.encode(body);

      var writer = BinaryWriter([]);
      writer.writeInt(4 + 4 + body.length + 1, 4, endian: Endian.little);
      writer.writeInt(4 + 4 + body.length + 1, 4, endian: Endian.little);
      writer.writeInt(clientSendToServer, 2, endian: Endian.little);
      writer.writeInt(encrypted, 1, endian: Endian.little);
      writer.writeInt(reserved, 1, endian: Endian.little);
      writer.writeBytes(buffer);
      writer.writeInt(0, 1, endian: Endian.little);
      return writer.buffer;
    } catch (e) {
      CoreLog.error(e);
      return [];
    }
  }

  String? deserializeDouyu(List<int> buffer) {
    try {
      var reader = BinaryReader(Uint8List.fromList(buffer));
      int fullMsgLength = reader.readInt32(endian: Endian.little); // fullMsgLength
      reader.readInt32(endian: Endian.little); // fullMsgLength2
      int bodyLength = fullMsgLength - 9;
      reader.readShort(endian: Endian.little); // packType
      reader.readByte(endian: Endian.little); // encrypted
      reader.readByte(endian: Endian.little); // reserved

      var bytes = reader.readBytes(bodyLength);

      reader.readByte(endian: Endian.little); // always 0
      return utf8.decode(bytes);
    } catch (e) {
      CoreLog.error(e);
      return null;
    }
  }

  // Upstream STT quirk workaround.
  dynamic sttToJObject(String str) {
    if (str.contains("//")) {
      var result = [];
      for (var field in str.split("//")) {
        if (field.isEmpty) {
          continue;
        }
        result.add(sttToJObject(field));
      }
      return result;
    }
    if (str.contains("@=")) {
      var result = {};
      for (var field in str.split('/')) {
        if (field.isEmpty) {
          continue;
        }
        var tokens = field.split("@=");
        var k = tokens[0];
        var v = unescapeSlashAt(tokens[1]);
        result[k] = sttToJObject(v);
      }
      return result;
    } else if (str.contains("@A=")) {
      return sttToJObject(unescapeSlashAt(str));
    } else {
      return unescapeSlashAt(str);
    }
  }

  String unescapeSlashAt(String str) {
    return str.replaceAll("@S", "/").replaceAll("@A", "@");
  }

  LiveMessageColor getColor(int type) {
    switch (type) {
      case 1:
        return LiveMessageColor(r: 255, g: 0, b: 0);
      case 2:
        return LiveMessageColor(r: 30, g: 135, b: 240);
      case 3:
        return LiveMessageColor(r: 122, g: 200, b: 75);
      case 4:
        return LiveMessageColor(r: 255, g: 127, b: 0);
      case 5:
        return LiveMessageColor(r: 155, g: 57, b: 244);
      case 6:
        return LiveMessageColor(r: 255, g: 105, b: 180);
      default:
        return LiveMessageColor.white;
    }
  }
}
