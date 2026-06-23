import 'package:pure_live/core/sites/sites.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/pagination/base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:pure_live/pagination/server_remote_page_mixin.dart';
import 'package:pure_live/pagination/models/base_controller_state.dart';

part 'hot_remote_provider.g.dart';

@riverpod
class HotRemote extends _$HotRemote with BaseControllerMixin, ServerRemotePageMixin<LiveRoom> {
  Site? site;

  @override
  BasePagedState<LiveRoom> build(String siteId) {
    site = Sites.of(siteId);
    return BasePagedState<LiveRoom>(
      controllerState: const BaseControllerState(),
      currentPage: firstPageKey,
      pageSize: defaultPageSize,
    );
  }

  @override
  Future<List<LiveRoom>> fetchServerRemoteData(int pageKey, int pageSize) async {
    return await site!.liveSite.getRecommendRooms(page: pageKey, pageSize: pageSize);
  }

  Future<void> loadFirstTime() async {
    if (state.items.isEmpty) {
      await loadRemoteData(firstPageKey);
    }
  }

  Future<void> loadNextPage() async {
    await loadNextRemotePage();
  }

  Future<void> refreshData() async {
    await refreshRemoteData();
  }
}
