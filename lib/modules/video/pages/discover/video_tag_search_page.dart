import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// One archive tag's result page — the reference app sends a tag chip to its
/// search screen, and that is exactly this: a keyword paged through the video
/// search endpoint, with the tag name as the keyword.
class VideoTagSearchPage extends ConsumerStatefulWidget {
  const VideoTagSearchPage({super.key, required this.keyword});

  final String keyword;

  @override
  ConsumerState<VideoTagSearchPage> createState() => _VideoTagSearchPageState();
}

class _VideoTagSearchPageState extends ConsumerState<VideoTagSearchPage> {
  late final PagingParam<MusicArchive> _param = PagingParam<MusicArchive>(
    mode: PagingMode.serverRemote,
    pageSize: 20,
    keepAlive: false,
    fetchRemote: (page, size) => BilibiliMusicApi.instance.searchVideos(widget.keyword, page: page, pageSize: size),
  );

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    return TvPageScaffold(
      title: widget.keyword,
      child: BasePagedTvView<MusicArchive>(
        param: _param,
        getNotifier: () => ref.read(pagingCoreProvider(_param).notifier),
        gridDelegate: TvAdaptiveGrid.media(
          context,
          crossAxisCount: themeState.denseRoomLayout,
          mainAxisSpacing: themeState.mainAxisSpacing.w,
          crossAxisSpacing: themeState.crossAxisSpacing.w,
          childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
        ),
        itemBuilder: (context, archive, index) =>
            VideoCard(archive: archive, onTap: () => openVideoArchive(context, ref, archive)),
      ),
    );
  }
}
