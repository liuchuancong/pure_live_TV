import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
// Leaf model import: the live result rows open the app's own room player.
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/video/models/video_pgc_models.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// The full-type search section, newBV's search screen for TV: hotwords while
/// idle, then video / user / movie results per keyword.
class VideoSearchSection extends ConsumerStatefulWidget {
  const VideoSearchSection({super.key});

  @override
  ConsumerState<VideoSearchSection> createState() => _VideoSearchSectionState();
}

class _VideoSearchSectionState extends ConsumerState<VideoSearchSection> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, PagingParam<MusicArchive>> _videoParams = {};
  String _keyword = '';
  int _typeIndex = 0;
  List<Hotword> _hotwords = [];

  static const _typeLabels = [
    ('video_search_type_video', Icons.movie_outlined),
    ('video_search_type_user', Icons.person_outline_rounded),
    ('video_search_type_pgc', Icons.live_tv_outlined),
    ('video_search_type_live', Icons.wifi_tethering_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadHotwords();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHotwords() async {
    try {
      final words = await BilibiliUgcApi.instance.getHotwords();
      if (!mounted) return;
      setState(() => _hotwords = words);
    } catch (_) {}
  }

  void _submit(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    setState(() => _keyword = trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
          child: Row(
            children: [
              SizedBox(
                width: 560.sp,
                child: TvInputField(
                  controller: _controller,
                  hint: i18n('video_search_hint'),
                  height: 64.sp,
                  maxLines: 1,
                  onSubmitted: _submit,
                ),
              ),
              SizedBox(width: 16.sp),
              TvButton(
                title: i18n('search_live'),
                icon: Icon(Icons.search_rounded, size: 28.sp),
                size: TvButtonSize.mini,
                onTap: () => _submit(_controller.text),
              ),
              if (_keyword.isNotEmpty) ...[
                SizedBox(width: 20.sp),
                for (final (index, (label, icon)) in _typeLabels.indexed) ...[
                  TvButton(
                    key: ValueKey('search_type_$index'),
                    title: i18n(label),
                    icon: Icon(icon, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: _typeIndex != index,
                    onTap: () => setState(() => _typeIndex = index),
                  ),
                  SizedBox(width: 10.sp),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: _keyword.isEmpty ? _HotwordBoard(hotwords: _hotwords, onPick: _submit) : _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    switch (_typeIndex) {
      case 1:
        return _UserResults(keyword: _keyword);
      case 2:
        return _PgcResults(keyword: _keyword);
      case 3:
        return _LiveResults(keyword: _keyword);
      default:
        final themeState = ref.watch(themeSettingsControllerProvider);
        final param = _videoParams.putIfAbsent(
          _keyword,
          () => PagingParam<MusicArchive>(
            mode: PagingMode.serverRemote,
            pageSize: 20,
            keepAlive: true,
            fetchRemote: (page, size) => BilibiliMusicApi.instance.searchVideos(_keyword, page: page, pageSize: size),
          ),
        );
        return BasePagedTvView<MusicArchive>(
          key: ValueKey('video_search_$_keyword'),
          param: param,
          getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: themeState.denseRoomLayout,
            mainAxisSpacing: themeState.mainAxisSpacing.w,
            crossAxisSpacing: themeState.crossAxisSpacing.w,
            childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
          ),
          itemBuilder: (context, archive, index) => VideoCard(
            archive: archive,
            onTap: () => VideoDetailRoute(archive).push(context),
          ),
        );
    }
  }
}

/// The idle board: trending words from the search square, the entry newBV's
/// TV search starts from.
class _HotwordBoard extends StatelessWidget {
  const _HotwordBoard({required this.hotwords, required this.onPick});

  final List<Hotword> hotwords;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (hotwords.isEmpty) {
      return Center(
        child: Text(
          i18n('music_search_empty_hint'),
          style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
        ),
      );
    }
    return DpadRegion(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, size: 26.sp, color: accent),
                SizedBox(width: 8.sp),
                Text(i18n('video_search_hotwords'), style: AppTextStyles.t20W600.copyWith(color: accent)),
              ],
            ),
            SizedBox(height: 16.sp),
            Wrap(
              spacing: 12.sp,
              runSpacing: 12.sp,
              children: [
                for (final (index, word) in hotwords.indexed)
                  TvFocusable(
                    autofocus: index == 0,
                    onTap: () => onPick(word.keyword),
                    builder: (context, focused, child) => AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
                      decoration: BoxDecoration(
                        color: tvTheme.cardColor,
                        borderRadius: BorderRadius.circular(24.sp),
                        border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}',
                            style: AppTextStyles.t16W700.copyWith(
                              color: index < 3 ? Colors.redAccent : tvTheme.secondaryTextColor,
                            ),
                          ),
                          SizedBox(width: 8.sp),
                          Text(
                            word.keyword,
                            style: AppTextStyles.t16W500.copyWith(color: tvTheme.primaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// User results: a list row per UP, opening the shared user-space page.
class _UserResults extends ConsumerStatefulWidget {
  const _UserResults({required this.keyword});

  final String keyword;

  @override
  ConsumerState<_UserResults> createState() => _UserResultsState();
}

class _UserResultsState extends ConsumerState<_UserResults> {
  final List<SearchUserItem> _users = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await BilibiliUgcApi.instance.searchUsers(widget.keyword);
      if (!mounted) return;
      setState(() {
        _users.addAll(users);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_loading && _users.isEmpty) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_error != null && _users.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    return DpadRegion(
      child: ListView.builder(
        padding: EdgeInsets.all(24.sp),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return TvFocusable(
            onTap: () => UgcUserSpaceRoute(user.mid, user.uname).push(context),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.sp),
              padding: EdgeInsets.all(14.sp),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.uname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                        ),
                        if (user.sign.isNotEmpty)
                          Text(
                            user.sign,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${readableCount(user.fans.toString())} ${i18n('video_followers')}',
                    style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Movie results: PGC seasons, straight into the season page.
class _PgcResults extends ConsumerStatefulWidget {
  const _PgcResults({required this.keyword});

  final String keyword;

  @override
  ConsumerState<_PgcResults> createState() => _PgcResultsState();
}

class _PgcResultsState extends ConsumerState<_PgcResults> {
  List<SearchPgcItem> _seasons = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final seasons = await BilibiliUgcApi.instance.searchPgc(widget.keyword);
      if (!mounted) return;
      setState(() {
        _seasons = seasons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_loading && _seasons.isEmpty) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_error != null && _seasons.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: GridView.builder(
        padding: EdgeInsets.all(24.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 16.w,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.72,
        ),
        itemCount: _seasons.length,
        itemBuilder: (context, index) {
          final season = _seasons[index];
          return TvFocusable(
            onTap: () => VideoSeasonRoute(
              PgcItem(seasonId: season.seasonId, title: season.title, cover: season.cover),
            ).push(context),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(14.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.sp),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14.sp)),
                      child: CachedNetworkImage(
                        imageUrl: season.cover,
                        fit: BoxFit.cover,
                        memCacheWidth: 480,
                        errorWidget: (_, _, _) => Container(color: Colors.black26),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.sp),
                      child: Text(
                        season.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W600.copyWith(color: tvTheme.primaryTextColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Live-room results: each row opens the app's own live player on the
/// bilibili platform — the video module searches, the live domain plays.
class _LiveResults extends ConsumerStatefulWidget {
  const _LiveResults({required this.keyword});

  final String keyword;

  @override
  ConsumerState<_LiveResults> createState() => _LiveResultsState();
}

class _LiveResultsState extends ConsumerState<_LiveResults> {
  List<SearchLiveItem> _rooms = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rooms = await BilibiliUgcApi.instance.searchLives(widget.keyword);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_loading && _rooms.isEmpty) {
      return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    }
    if (_error != null && _rooms.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_rooms.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('video_search_live_empty'), subtitle: '');
    }
    return DpadRegion(
      child: ListView.builder(
        padding: EdgeInsets.all(24.sp),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final live = room.liveStatus == 1;
          return TvFocusable(
            onTap: () => LivePlayRoute(
              LivePlayArgs(platform: 'bilibili', roomId: room.roomId.toString()),
            ).push(context),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.sp),
              height: 118.sp,
              padding: EdgeInsets.all(10.sp),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.sp),
                        child: CachedNetworkImage(
                          imageUrl: room.cover,
                          width: 180.sp,
                          height: 98.sp,
                          fit: BoxFit.cover,
                          memCacheWidth: 480,
                          errorWidget: (_, _, _) => Container(width: 180.sp, color: Colors.black26),
                        ),
                      ),
                      if (live)
                        Positioned(
                          left: 6.sp,
                          top: 6.sp,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                            child: Text(
                              i18n('video_search_live_badge'),
                              style: AppTextStyles.t14W600.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 14.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          room.uname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                        ),
                        if (room.online > 0)
                          Text(
                            '${readableCount(room.online.toString())} ${i18n('video_search_live_online')}',
                            style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
