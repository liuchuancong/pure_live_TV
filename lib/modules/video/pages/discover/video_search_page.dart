import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/modules/video/pages/discover/widgets/video_hotword_board.dart';
import 'package:pure_live/modules/video/pages/discover/widgets/video_user_results.dart';
import 'package:pure_live/modules/video/pages/discover/widgets/video_pgc_results.dart';


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
          child: _keyword.isEmpty ? VideoHotwordBoard(hotwords: _hotwords, onPick: _submit) : _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    switch (_typeIndex) {
      case 1:
        return VideoUserResults(keyword: _keyword);
      case 2:
        return VideoPgcResults(keyword: _keyword);
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
          gridDelegate: TvAdaptiveGrid.media(
            context,
            crossAxisCount: themeState.denseRoomLayout,
            mainAxisSpacing: themeState.mainAxisSpacing.w,
            crossAxisSpacing: themeState.crossAxisSpacing.w,
            childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
          ),
          itemBuilder: (context, archive, index) => VideoCard(
            archive: archive,
            onTap: () => openVideoArchive(context, ref, archive),
          ),
        );
    }
  }
}

class VideoUserResultsState extends ConsumerState<VideoUserResults> {
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
                          style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
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
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
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

class VideoPgcResultsState extends ConsumerState<VideoPgcResults> {
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
        gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
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
                        style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
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
