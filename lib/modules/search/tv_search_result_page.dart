import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/widgets/tv_room_card.dart';
import 'package:pure_live/pagination/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/core/utils/favorite_operation_util.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/core/utils/remote_receiver/tv_remote_receiver.dart';

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
  dynamic _remoteReceiverNotifier;
  late PagingParam<LiveRoom> _currentParam;

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
    if (_remoteReceiverNotifier == null) return;
    _remoteReceiverNotifier.onStreamerSearch = (searchText) {
      _handleIncomingSearch(searchText);
    };
    _remoteReceiverNotifier.onRoomPush = (searchText) {
      _handleIncomingSearch(searchText);
    };
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

    if (siteId == Sites.kuaishouSite) {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverAll,
        pageSize: 12,
        keepAlive: false,
        fetchAll: () async {
          final list = await liveSite.searchRooms(_currentKeyword, page: 1, pageSize: 12);
          return list;
        },
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
        fetchFixed: (bigPage, size) async {
          final list = await liveSite.searchRooms(_currentKeyword, page: bigPage, pageSize: size);
          return list;
        },
      );
    } else {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverRemote,
        pageSize: 12,
        keepAlive: false,
        fetchRemote: (page, size) async {
          final list = await liveSite.searchRooms(_currentKeyword, page: page, pageSize: size);
          return list;
        },
      );
    }
  }

  @override
  void dispose() {
    if (_remoteReceiverNotifier != null) {
      _remoteReceiverNotifier.onStreamerSearch = null;
      _remoteReceiverNotifier.onRoomPush = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      title: '搜索: $_currentKeyword (${widget.site})',
      child: TvTabView(
        memoryKey: "tv_search_rooms_view_${widget.site}",
        verticalEdge: DpadEdgeBehavior.leave,
        horizontalEdge: DpadEdgeBehavior.stop,
        child: BasePagedTvView<LiveRoom>(
          param: _currentParam,
          getNotifier: () => ref.read(pagingCoreProvider(_currentParam).notifier),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 32.sp,
            crossAxisSpacing: 32.sp,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, room, index) =>
              TvRoomCard(room: room, onLongPress: () => FavOperateUtil.toggleRoomFollowDialog(context, room)),
        ),
      ),
    );
  }
}
