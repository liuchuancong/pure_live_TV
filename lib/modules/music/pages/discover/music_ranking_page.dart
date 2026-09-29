import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class MusicRankingPage extends ConsumerStatefulWidget {
  const MusicRankingPage({super.key});

  @override
  ConsumerState<MusicRankingPage> createState() => MusicRankingPageState();
}

class MusicRankingPageState extends ConsumerState<MusicRankingPage> {
  late final PagingParam<MusicArchive> _param = PagingParam<MusicArchive>(
    mode: PagingMode.serverAll,
    pageSize: 12,
    keepAlive: true,
    fetchAll: () => BilibiliMusicApi.instance.getMusicRanking(),
  );

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    return BasePagedTvView<MusicArchive>(
      key: const ValueKey('music_ranking_grid'),
      param: _param,
      getNotifier: () => ref.read(pagingCoreProvider(_param).notifier),
      gridDelegate: TvAdaptiveGrid.media(
        context,
        crossAxisCount: themeState.denseRoomLayout,
        mainAxisSpacing: themeState.mainAxisSpacing.w,
        crossAxisSpacing: themeState.crossAxisSpacing.w,
        childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
      ),
      itemBuilder: (context, archive, index) =>
          MusicVideoCard(archive: archive, onTap: () => MusicArchiveRoute(archive).push(context)),
    );
  }
}
