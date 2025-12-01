import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller_panel.dart';

class VideoPlayer extends StatefulWidget {
  final VideoController controller;
  const VideoPlayer({super.key, required this.controller});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  VideoController get controller => widget.controller;

  Widget placeholderWidget() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      color: Get.theme.focusColor,
      child: CachedNetworkImage(
        cacheManager: CustomCacheManager.instance,
        imageUrl: controller.room.cover!,
        fit: BoxFit.fill,
        errorWidget: (context, error, stackTrace) => const Center(child: Icon(Icons.live_tv_rounded, size: 48)),
      ),
    );
  }

  Widget buildLoading() {
    return Material(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            color: Colors.black, // 设置你想要的背景色
          ),
          Container(
            color: Colors.black,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 6, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    return VideoControllerPanel(controller: controller);
    // return Obx(() {
    //   if (!controller.isPlaying.value) return buildLoading();
    //   if (controller.isPlaying.value) {
    //     return controller.globalPlayer.getVideoWidget(VideoControllerPanel(controller: controller));
    //   }
    //   return placeholderWidget();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: widget.controller.focusNode,
      autofocus: true,
      onKeyEvent: widget.controller.onKeyEvent,
      child: Scaffold(backgroundColor: Colors.black, body: _buildVideo()),
    );
  }
}
