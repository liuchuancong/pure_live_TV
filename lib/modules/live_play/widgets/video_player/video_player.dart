import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
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

  Widget _buildExoPlayerVideo() {
    return Stack(
      children: [
        BetterPlayer(
          key: widget.controller.playerKey,
          controller: widget.controller.betterPlayerController,
        ),
        _buildVideoPanel(),
      ],
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
      return _buildExoPlayerVideo();
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
