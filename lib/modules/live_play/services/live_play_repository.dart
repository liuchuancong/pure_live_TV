import 'package:pure_live/core/index.dart';

/// 直播播放页对 Sites 的唯一访问入口。
///
/// 收敛在单独文件里，避免页面/控制器散落对 core/sites 的直接依赖；
/// 若站点接口缺方法，只需在此适配（defensive），不改 core/sites。
class LivePlayRepository {
  const LivePlayRepository();

  /// 拉取房间详情。传入的 [hintRoom] 仅作平台/房间号来源，结果以站点返回为准。
  Future<LiveRoom> fetchRoomDetail({required LiveRoom hintRoom}) {
    return Sites.of(hintRoom.normalizedPlatformId).liveSite.getRoomDetail(
          roomId: hintRoom.normalizedRoomId,
          platform: hintRoom.normalizedPlatformId,
        );
  }

  Future<List<LivePlayQuality>> fetchPlayQualities(LiveRoom detail) async {
    try {
      return await Sites.of(detail.normalizedPlatformId).liveSite.getPlayQualites(detail: detail);
    } catch (_) {
      return const <LivePlayQuality>[];
    }
  }

  Future<List<String>> fetchPlayUrls(LiveRoom detail, LivePlayQuality quality) async {
    return await Sites.of(detail.normalizedPlatformId).liveSite.getPlayUrls(detail: detail, quality: quality);
  }

  /// 创建该平台的弹幕传输引擎；平台不支持时站点层会返回 EmptyDanmaku。
  LiveDanmaku createDanmaku(LiveRoom detail) {
    return Sites.of(detail.normalizedPlatformId).liveSite.getDanmaku();
  }
}
