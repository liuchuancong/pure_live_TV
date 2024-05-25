import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  Widget _buildPlayerVideo() {
    return KeyboardListener(
      focusNode: widget.controller.focusNode,
      autofocus: true,
      onKeyEvent: widget.controller.onKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Obx(
              () => widget.controller.mediaPlayerControllerInitialized.value
                  ? Chewie(
                      controller: widget.controller.chewieController,
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.all(0),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        clipBehavior: Clip.antiAlias,
                        color: Get.theme.focusColor,
                        child: CachedNetworkImage(
                          cacheManager: CustomCacheManager.instance,
                          imageUrl: widget.controller.room.cover!,
                          fit: BoxFit.contain,
                          errorWidget: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.live_tv_rounded, size: 48),
                          ),
                        ),
                      ),
                    ),
            ),
            _buildVideoPanel(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayerVideo();
  }
}
