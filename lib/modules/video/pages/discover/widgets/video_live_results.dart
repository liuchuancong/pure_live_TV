import 'package:dpad/dpad.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';

/// Live-room results, newBV's fifth search tab: rows open the live player,
/// the list pages on scroll end.
class VideoLiveResults extends ConsumerStatefulWidget {
  const VideoLiveResults({super.key, required this.keyword});

  final String keyword;

  @override
  ConsumerState<VideoLiveResults> createState() => _VideoLiveResultsState();
}

class _VideoLiveResultsState extends ConsumerState<VideoLiveResults> {
  final ScrollController _scroll = ScrollController();
  final List<SearchLiveItem> _rooms = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 300) _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = _page + 1;
      final rooms = await BilibiliUgcApi.instance.searchLives(widget.keyword, page: page);
      if (!mounted) return;
      setState(() {
        _rooms.addAll(rooms);
        _page = page;
        _hasMore = rooms.length >= 20;
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

  Future<void> _openRoom(SearchLiveItem room) async {
    try {
      final detail = await Sites.of(Sites.bilibiliSite).liveSite.getRoomDetail(
        roomId: '${room.roomId}',
        platform: Sites.bilibiliSite,
      );
      if (!mounted) return;
      LivePlayRoute(detail).push(context);
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('load_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_loading && _rooms.isEmpty) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_error != null && _rooms.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (!_loading && _rooms.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('video_search_live_empty'), subtitle: '');
    }
    return DpadRegion(
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(24.ts(context)),
        itemCount: _rooms.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _rooms.length) {
            return Padding(
              padding: EdgeInsets.all(14.ts(context)),
              child: Center(
                child: SizedBox(
                  width: 26.ts(context),
                  height: 26.ts(context),
                  child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                ),
              ),
            );
          }
          final room = _rooms[index];
          final live = room.liveStatus == 1;
          return TvFocusable(
            onTap: () => _openRoom(room),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.sp),
              padding: EdgeInsets.all(14.ts(context)),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.ts(context)),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.ts(context)),
                    child: CachedNetworkImage(
                      imageUrl: room.cover,
                      width: 120.ts(context),
                      height: 76.ts(context),
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      errorWidget: (_, _, _) => Container(color: Colors.black26),
                    ),
                  ),
                  SizedBox(width: 14.ts(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t16.copyWith(
                            fontWeight: FontWeight.w600,
                            color: tvTheme.primaryTextColor,
                          ),
                        ),
                        Text(
                          room.uname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.ts(context)),
                  if (live)
                    TvButton(
                      excludeFocus: true,
                      title: '${readableCount(room.online.toString())} ${i18n('video_search_live_online')}',
                      size: TvButtonSize.mini,
                    )
                  else
                    Text(
                      i18n('video_search_live_replay'),
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
