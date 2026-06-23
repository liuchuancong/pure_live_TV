import 'package:pure_live/core/sites/sites.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/pagination/base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:pure_live/pagination/server_fixed_page_mixin.dart';
import 'package:pure_live/pagination/models/base_controller_state.dart';

part 'hot_fixed_provider.g.dart';

@riverpod
class HotFixed extends _$HotFixed with BaseControllerMixin, ServerFixedPageMixin<LiveRoom> {
  Site? site;
  int? fixedSize;

  @override
  BasePagedState<LiveRoom> build(String siteId) {
    site = Sites.of(siteId);
    fixedSize = siteId == Sites.douyuSite ? 40 : (siteId == Sites.huyaSite ? 120 : 20);
    return BasePagedState<LiveRoom>(
      controllerState: const BaseControllerState(),
      currentPage: firstPageKey,
      pageSize: defaultPageSize,
    );
  }

  @override
  int get fixedServerPageSize => fixedSize!;

  @override
  Future<List<LiveRoom>> fetchFixedNetworkData(int bigPage, int fixedSize) async {
    return await site!.liveSite.getRecommendRooms(page: bigPage, pageSize: fixedSize);
  }

  Future<void> loadFirstTime() async {
    if (state.items.isEmpty) {
      await loadFixedData(firstPageKey);
    }
  }

  Future<void> loadNextPage() async {
    await loadNextFixedPage();
  }
}
