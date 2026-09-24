import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/remote/index.dart';
import 'package:pure_live/features/search/tv_search_provider.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/app/router/app_router.dart';

class TvSearchResultPage extends ConsumerStatefulWidget {
  final String keyword;
  final String site;
  final String searchType;

  const TvSearchResultPage({super.key, required this.keyword, required this.site, required this.searchType});

  @override
  ConsumerState<TvSearchResultPage> createState() => _TvSearchResultPageState();
}

class _TvSearchResultPageState extends ConsumerState<TvSearchResultPage> {
  late String _currentKeyword;
  TvRemoteReceiver? _remoteReceiverNotifier;
  late PagingParam<LiveRoom> _currentParam;

  bool get _isStreamerSearch => widget.searchType == kSearchTypeStreamer;

  @override
  void initState() {
    super.initState();
    _currentKeyword = widget.keyword;
    _initSearchPagingParam();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remoteReceiverNotifier = ref.read(tvRemoteReceiverProvider.notifier);
      _bindRemoteCallbacks();
    });
  }

  void _bindRemoteCallbacks() {
    final receiver = _remoteReceiverNotifier;
    if (receiver == null) return;
    receiver.onStreamerSearch = _handleIncomingSearch;
    receiver.onRoomPush = _handleIncomingSearch;
  }

  void _handleIncomingSearch(String text) {
    if (text.trim().isEmpty) return;

    _currentKeyword = text.trim();
    _initSearchPagingParam();

    if (mounted) {
      setState(() {});
      ref.read(pagingCoreProvider(_currentParam).notifier).refresh();
    }
  }

  void _initSearchPagingParam() {
    final activeSites = Sites().availableSites(containsAll: false);

    var selectedSite = activeSites.first;
    for (var site in activeSites) {
      if (site.name == widget.site || site.id == widget.site) {
        selectedSite = site;
        break;
      }
    }

    final liveSite = Sites.of(selectedSite.id).liveSite;
    final siteId = selectedSite.id;

    // Streamer searches go through searchAnchors and are mapped onto LiveRoom
    // so the paged grid and TvRoomCard keep working unchanged.
    Future<List<LiveRoom>> fetch(int page, int size) async {
      if (!_isStreamerSearch) {
        return liveSite.searchRooms(_currentKeyword, page: page, pageSize: size);
      }
      final anchors = await liveSite.searchAnchors(_currentKeyword, page: page, pageSize: size);
      return anchors
          .map(
            (anchor) => LiveRoom(
              roomId: anchor.roomId,
              userId: anchor.roomId,
              nick: anchor.userName,
              title: anchor.userName,
              avatar: anchor.avatar,
              cover: anchor.avatar,
              platform: siteId,
              status: anchor.liveStatus,
              liveStatus: anchor.liveStatus ? LiveStatus.live : LiveStatus.offline,
            ),
          )
          .toList();
    }

    // A platform that resolves an exact room id or share link in a single
    // request must not be paged: every later page is guaranteed empty, so one
    // request replaces the whole paging sequence.
    final bool exactOnly =
        !_isStreamerSearch &&
        liveSite is LiveSearchPaginationPolicy &&
        !(liveSite as LiveSearchPaginationPolicy).supportsSearchPaginationFor(_currentKeyword);

    if (exactOnly) {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverAll,
        pageSize: 12,
        keepAlive: false,
        fetchAll: () => fetch(1, 12),
      );
    } else if (siteId == Sites.kuaishouSite) {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverAll,
        pageSize: 12,
        keepAlive: false,
        fetchAll: () => fetch(1, 12),
      );
    } else if (siteId == Sites.douyuSite || siteId == Sites.huyaSite || siteId == Sites.douyinSite) {
      final int fixedSize = switch (siteId) {
        Sites.douyuSite => 40,
        Sites.huyaSite => 120,
        Sites.douyinSite => 20,
        _ => 12,
      };
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverFixedSize,
        pageSize: 12,
        fixedServerSize: fixedSize,
        keepAlive: false,
        fetchFixed: (bigPage, size) => fetch(bigPage, size),
      );
    } else {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverRemote,
        pageSize: 12,
        keepAlive: false,
        fetchRemote: (page, size) => fetch(page, size),
      );
    }
  }

  @override
  void dispose() {
    final receiver = _remoteReceiverNotifier;
    if (receiver != null) {
      receiver.onStreamerSearch = null;
      receiver.onRoomPush = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    // The results this search has loaded so far. The player takes it as the
    // up/down channel list and fills the playlist panel with it, so a room
    // opened from a search switches within those results instead of falling
    // back to watch history.
    final List<LiveRoom> rooms = ref.watch(pagingCoreProvider(_currentParam).select((state) => state.items));

    return TvPageScaffold(
      title: '${i18n('search')}: $_currentKeyword (${widget.site})',
      child: TvTabView(
        memoryKey: "tv_search_rooms_view_${widget.site}_${widget.searchType}",
        verticalEdge: DpadEdgeBehavior.leave,
        horizontalEdge: DpadEdgeBehavior.stop,
        child: BasePagedTvView<LiveRoom>(
          param: _currentParam,
          getNotifier: () => ref.read(pagingCoreProvider(_currentParam).notifier),
          onGoLogin: () => const AccountSettingsRoute().push(context),
          emptyScene: EmptyScene.searchResult,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: themeState.denseRoomLayout,
            mainAxisSpacing: mainSpacing.w,
            crossAxisSpacing: crossSpacing.w,
            childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
          ),
          itemBuilder: (context, room, index) => TvRoomCard(
            room: room,
            playlist: rooms,
            onLongPress: () => FavOperateUtil.toggleRoomFollowDialog(context, room),
          ),
        ),
      ),
    );
  }
}