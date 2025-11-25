import 'dart:math';
import 'package:get/get.dart';
import 'package:flv_lzc/fijkplayer.dart';
import 'package:pure_live/common/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:pure_live/modules/live_play/widgets/video_player/fijk_helper.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller_panel.dart';

class VideoPlayer extends StatefulWidget {
  final VideoController controller;
  const VideoPlayer({
    super.key,
    required this.controller,
  });

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  bool hasRender = false;
  Widget _buildVideoPanel() {
    return VideoControllerPanel(
      controller: widget.controller,
    );
  }

  Widget _buildIjkPanel(
    FijkPlayer fijkPlayer,
    FijkData fijkData,
    BuildContext context,
    Size viewSize,
    Rect texturePos,
  ) {
    Rect rect = widget.controller.ijkPlayer.value.fullScreen
        ? Rect.fromLTWH(0, 0, viewSize.width, viewSize.height)
        : Rect.fromLTRB(
            max(0.0, texturePos.left),
            max(0.0, texturePos.top),
            min(viewSize.width, texturePos.right),
            min(viewSize.height, texturePos.bottom),
          );
    return Positioned.fromRect(
      rect: rect,
      child: VideoControllerPanel(controller: widget.controller),
    );
  }

  Widget _buildIjkPlayerVideo() {
    return Material(
      key: ValueKey(widget.controller.videoFit.value),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.passthrough,
          children: [
            Container(
              color: Colors.black, // 设置你想要的背景色
            ),
            FijkView(
              player: widget.controller.ijkPlayer,
              fit: FijkHelper.getIjkBoxFit(widget.controller.videoFit.value),
              fs: false,
              color: Colors.black,
              panelBuilder: (
                FijkPlayer fijkPlayer,
                FijkData fijkData,
                BuildContext context,
                Size viewSize,
                Rect texturePos,
              ) =>
                  Container(),
            ),
            VideoControllerPanel(controller: widget.controller),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (widget.controller.videoPlayerIndex == 0) {
      return Obx(() => widget.controller.mediaPlayerControllerInitialized.value
          ? media_kit_video.Video(
              key: widget.controller.key,
              controller: widget.controller.mediaPlayerController,
              fit: widget.controller.settings.videofitArrary[widget.controller.settings.videoFitIndex.value],
              controls: widget.controller.room.platform == Sites.iptvSite
                  ? media_kit_video.MaterialVideoControls
                  : (state) => _buildVideoPanel(),
            )
          : Card(
              elevation: 0,
              margin: const EdgeInsets.all(0),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              clipBehavior: Clip.antiAlias,
              color: Get.theme.focusColor,
              child: CachedNetworkImage(
                cacheManager: CustomCacheManager.instance,
                imageUrl: widget.controller.room.cover!,
                fit: BoxFit.fill,
                errorWidget: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.live_tv_rounded, size: 48),
                ),
              ),
            ));
    } else {
      return _buildIjkPlayerVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: widget.controller.focusNode,
      autofocus: true,
      onKeyEvent: widget.controller.onKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildVideo(),
      ),
    );
  }
}
