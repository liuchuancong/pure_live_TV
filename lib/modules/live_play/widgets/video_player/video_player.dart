import 'package:get/get.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:pure_live/common/index.dart';
import 'package:better_player/better_player.dart';
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
  Widget _buildVideoPanel() {
    return VideoControllerPanel(
      controller: widget.controller,
    );
  }

  ImageProvider? getRoomCover(cover) {
    try {
      return CachedNetworkImageProvider(cover);
    } catch (e) {
      return null;
    }
  }

  FijkFit getFijkFit(BoxFit boxFit) {
    FijkFit fijkFit = FijkFit.contain;
    if (boxFit == BoxFit.contain) {
      fijkFit = FijkFit.contain;
    } else if (boxFit == BoxFit.cover) {
      fijkFit = FijkFit.cover;
    } else if (boxFit == BoxFit.fill) {
      fijkFit = FijkFit.fill;
    } else if (boxFit == BoxFit.fitHeight) {
      fijkFit = FijkFit.fitHeight;
    } else if (boxFit == BoxFit.fitWidth) {
      fijkFit = FijkFit.fitWidth;
    }
    return fijkFit;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.videoPlayerIndex == 0) {
      return Stack(
        children: [
          BetterPlayer(
            key: widget.controller.playerKey,
            controller: widget.controller.mobileController!,
          ),
          _buildVideoPanel(),
        ],
      );
    }
    if (widget.controller.videoPlayerIndex == 1) {
      return Obx(
        () => !widget.controller.playerRefresh.value
            ? Stack(
                children: [
                  FijkView(
                    player: widget.controller.fijkPlayer,
                    color: Colors.black,
                    width: double.infinity,
                    fit: getFijkFit(widget.controller.videoFit.value),
                    cover: getRoomCover(widget.controller.room.cover),
                    fs: false,
                  ),
                  _buildVideoPanel()
                ],
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
              ),
      );
    }
    if (widget.controller.videoPlayerIndex == 2) {
      return Obx(() => widget.controller.mediaPlayerControllerInitialized.value
          ? media_kit_video.Video(
              key: widget.controller.key,
              controller: widget.controller.mediaPlayerController,
              fit: widget.controller.videoFit.value,
              controls: (state) => _buildVideoPanel(),
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
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      color: Get.theme.focusColor,
      child: CachedNetworkImage(
        imageUrl: widget.controller.room.cover!,
        fit: BoxFit.fill,
        errorWidget: (context, error, stackTrace) => const Center(
          child: Icon(Icons.live_tv_rounded, size: 48),
        ),
      ),
    );
  }
}
