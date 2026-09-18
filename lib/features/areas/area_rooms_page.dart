import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

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
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = 32 + themeState.crossAxisSpacing - ThemeSettingsController.defaultSpacing;
    final double mainSpacing = 32 + themeState.mainAxisSpacing - ThemeSettingsController.defaultSpacing;

    return TvPageScaffold(
      title: widget.subCategory.areaName,
      // No Expanded here: TvScaffold places its child inside a Stack, which is
      // not a Flex, so an Expanded child asserted during layout and the whole
      // room list failed to render.
      child: TvTabView(
        memoryKey: "area_rooms_view_${widget.site.id}_${widget.subCategory.areaId}",
        verticalEdge: DpadEdgeBehavior.leave,
        horizontalEdge: DpadEdgeBehavior.stop,
        child: BasePagedTvView<LiveRoom>(
          key: ValueKey('area_room_grid_${widget.site.id}_${widget.subCategory.areaId}'),
          param: _currentParam,
          getNotifier: () => ref.read(pagingCoreProvider(_currentParam).notifier),
          emptyScene: EmptyScene.areaRooms,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: mainSpacing.w,
            crossAxisSpacing: crossSpacing.w,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, room, index) =>
              TvRoomCard(room: room, onLongPress: () => FavOperateUtil.toggleRoomFollowDialog(context, room)),
        ),
      ),
    );
  }
}