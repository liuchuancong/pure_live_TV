import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'proto/douyin.pb.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:pure_live/core/site/douyin_site.dart';
import 'package:pure_live/common/utils/js_engine.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/core/common/web_socket_util.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/core/common/http_client.dart' as http;

class DouyinDanmakuArgs {
  final String webRid;
  final String roomId;
  final String userId;
  final String cookie;
  DouyinDanmakuArgs({
    required this.webRid,
    required this.roomId,
    required this.userId,
    required this.cookie,
  });
  @override
  String toString() {
    return json.encode({
      "webRid": webRid,
      "roomId": roomId,
      "userId": userId,
      "cookie": cookie,
    });
  }
}

class DouyinDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 10 * 1000;

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;
  String serverUrl = "wss://webcast3-ws-web-lq.douyin.com/webcast/im/push/v2/";
  late DouyinDanmakuArgs danmakuArgs;
  WebScoketUtils? webScoketUtils;

  @override
  Future start(dynamic args) async {
    danmakuArgs = args as DouyinDanmakuArgs;
    var ts = DateTime.now().millisecondsSinceEpoch;
    JsEngine.init();
    await JsEngine.loadDouyinSdk();
    var xMsStub = getMsStub(danmakuArgs.roomId, danmakuArgs.userId);
    JsEvalResult jsEvalResult = await JsEngine.evaluateAsync("get_sign('$xMsStub')");
    var uri = Uri.parse(serverUrl).replace(scheme: "wss", queryParameters: {
      "app_name": "douyin_web",
      "version_code": "180800",
      "webcast_sdk_version": "1.0.14-beta.0",
      "update_version_code": "1.0.14-beta.0",
      "compress": "gzip",
      // "internal_ext":
      //     "internal_src:dim|wss_push_room_id:${danmakuArgs.roomId}|wss_push_did:${danmakuArgs.userId}|dim_log_id:20230626152702E8F63662383A350588E1|fetch_time:1687764422114|seq:1|wss_info:0-1687764422114-0-0|wrds_kvs:WebcastRoomRankMessage-1687764036509597990_InputPanelComponentSyncData-1687736682345173033_WebcastRoomStatsMessage-1687764414427812578",
      "cursor": "h-1_t-${ts}_r-1_d-1_u-1",
      "host": "https://live.douyin.com",
      "aid": "6383",
      "live_id": "1",
      "did_rule": "3",
      "debug": "false",
      "maxCacheMessageNumber": "20",
      "endpoint": "live_pc",
      "support_wrds": "1",
      "im_path": "/webcast/im/fetch/",
      "user_unique_id": danmakuArgs.userId,
      "device_platform": "web",
      "cookie_enabled": "true",
      "screen_width": "1920",
      "screen_height": "1080",
      "browser_language": "zh-CN",
      "browser_platform": "Win32",
      "browser_name": "Mozilla",
      "browser_version": DouyinSite.kDefaultUserAgent.replaceAll("Mozilla/", ""),
      "browser_online": "true",
      "tz_name": "Asia/Shanghai",
      "identity": "audience",
      "room_id": danmakuArgs.roomId,
      "heartbeatDuration": "0",
      "signature": jsEvalResult.stringResult
    });

    // var sign = await getSignature(danmakuArgs.roomId, danmakuArgs.userId);

    var url = "$uri";
    var backupUrl = url.replaceAll("webcast3-ws-web-lq", "webcast5-ws-web-lf");
    webScoketUtils = WebScoketUtils(
      url: url,
      backupUrl: backupUrl,
      headers: {
        "User-Agnet": DouyinSite.kDefaultUserAgent,
        "Cookie": danmakuArgs.cookie,
      },
      heartBeatTime: heartbeatTime,
      onMessage: (e) {
        decodeMessage(e);
      },
      onReady: () {
        onReady?.call();
        joinRoom(args);
      },
      onHeartBeat: () {
        heartbeat();
      },
      onReconnect: () {
        onClose?.call("与服务器断开连接，正在尝试重连");
      },
      onClose: (e) {
        onClose?.call("服务器连接失败$e");
      },
    );
    webScoketUtils?.connect();
  }

  @override
  void heartbeat() {
    var obj = PushFrame();
    obj.payloadType = 'hb';
    webScoketUtils?.sendMessage(obj.writeToBuffer());
  }

  void decodeMessage(dynamic args) {
    // CoreLog.i(args.toString());

    var wssPackage = PushFrame.fromBuffer(args);

    var logId = wssPackage.logId;
    var decompressed = gzip.decode(wssPackage.payload);
    var payloadPackage = Response.fromBuffer(decompressed);
    if (payloadPackage.needAck) {
      sendAck(logId, payloadPackage.internalExt);
      //return;
    }
    for (var msg in payloadPackage.messagesList) {
      if (msg.method == 'WebcastChatMessage') {
        unPackWebcastChatMessage(msg.payload);
      } else if (msg.method == 'WebcastRoomUserSeqMessage') {
        unPackWebcastRoomUserSeqMessage(msg.payload);
      }
    }
  }

  void unPackWebcastChatMessage(List<int> payload) {
    var chatMessage = ChatMessage.fromBuffer(payload);
    onMessage?.call(
      LiveMessage(
        type: LiveMessageType.chat,
        color: LiveMessageColor.white,
        //暂不知道具体怎么转换颜色
        // color: chatMessage.common.fullScreenTextColor.
        //     ? LiveMessageColor.white
        //     : LiveMessageColor.numberToColor(color),
        message: chatMessage.content,
        userName: chatMessage.user.nickName,
      ),
    );
  }

  /// 获取Websocket签名
  /// - [roomId] 房间ID, 例如：7382735338101328680
  /// - [uniqueId] 用户唯一ID, 例如：7273033021933946427
  ///
  /// 服务端代码：https://github.com/lovelyyoshino/douyin_python，请自行部署后使用
  Future<String> getSignature(String roomId, String uniqueId) async {
    try {
      var signResult = await http.HttpClient.instance.postJson(
        "https://dy.nsapps.cn/signature",
        queryParameters: {},
        header: {"Content-Type": "application/json"},
        data: {"roomId": roomId, "uniqueId": uniqueId},
      );
      return signResult["data"]["signature"];
    } catch (e) {
      return "";
    }
  }

  void unPackWebcastRoomUserSeqMessage(List<int> payload) {
    var roomUserSeqMessage = RoomUserSeqMessage.fromBuffer(payload);

    onMessage?.call(
      LiveMessage(
        type: LiveMessageType.online,
        data: roomUserSeqMessage.totalUser.toInt(),
        color: LiveMessageColor.white,
        message: "",
        userName: "",
      ),
    );
  }

  void sendAck(dynamic logId, String internalExt) {
    var obj = PushFrame();
    obj.payloadType = 'ack';
    obj.logId = logId;
    obj.payloadType = internalExt;
    webScoketUtils?.sendMessage(obj.writeToBuffer());
  }

  void joinRoom(dynamic args) {
    var obj = PushFrame();
    obj.payloadType = 'hb';
    webScoketUtils?.sendMessage(obj.writeToBuffer());
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }

  String getMsStub(String liveRoomRealId, String userUniqueId) {
    Map<String, dynamic> params = {
      "live_id": "1",
      "aid": "6383",
      "version_code": 180800,
      "webcast_sdk_version": '1.0.14-beta.0',
      "room_id": liveRoomRealId,
      "sub_room_id": "",
      "sub_channel_id": "",
      "did_rule": "3",
      "user_unique_id": userUniqueId,
      "device_platform": "web",
      "device_type": "",
      "ac": "",
      "identity": "audience",
    };

    String sigParams = params.entries.map((e) => '${e.key}=${e.value}').join(',');

    var bytes = utf8.encode(sigParams);
    var digest = md5.convert(bytes);
    return digest.toString();
  }
}
