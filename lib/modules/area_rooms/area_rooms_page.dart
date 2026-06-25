import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/widgets/tv_room_card.dart';
import 'package:pure_live/pagination/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AreaRoomsPage extends ConsumerStatefulWidget {
  final Site site;
  final LiveArea subCategory;

  const AreaRoomsPage({super.key, required this.site, required this.subCategory});

  @override
  ConsumerState<AreaRoomsPage> createState() => _AreaRoomsPageState();
}

class _AreaRoomsPageState extends ConsumerState<AreaRoomsPage> {
  late final PagingParam<LiveRoom> _currentParam;

  @override
  void initState() {
    super.initState();
    _initPagingParam();
  }

  void _initPagingParam() {
    final liveSite = widget.site.liveSite;
    final siteId = widget.site.id;

    if (siteId == Sites.kuaishouSite) {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverAll,
        pageSize: 12,
        keepAlive: true,
        fetchAll: () async {
          final list = await liveSite.getCategoryRooms(widget.subCategory, page: 1);
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
        keepAlive: true,
        fetchFixed: (bigPage, size) async {
          final list = await liveSite.getCategoryRooms(widget.subCategory, page: bigPage);
          return list;
        },
      );
    } else {
      _currentParam = PagingParam<LiveRoom>(
        mode: PagingMode.serverRemote,
        pageSize: 12,
        keepAlive: true,
        fetchRemote: (page, size) async {
          final list = await liveSite.getCategoryRooms(widget.subCategory, page: page);
          return list;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      title: widget.subCategory.areaName,
      child: Expanded(
        child: TvTabView(
          memoryKey: "area_rooms_view_${widget.site.id}_${widget.subCategory.areaId}",
          verticalEdge: DpadEdgeBehavior.leave,
          horizontalEdge: DpadEdgeBehavior.stop,
          child: BasePagedTvView<LiveRoom>(
            key: ValueKey('area_room_grid_${widget.site.id}_${widget.subCategory.areaId}'),
            param: _currentParam,
            getNotifier: () => ref.read(pagingCoreProvider(_currentParam).notifier),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 32.sp,
              crossAxisSpacing: 32.sp,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, room, index) => TvRoomCard(room: room, onLongPress: () {}, onTap: () {}),
          ),
        ),
      ),
    );
  }
}
