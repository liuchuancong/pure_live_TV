import 'package:pure_live/core/sites/sites.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/pagination/base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:pure_live/pagination/local_reactive_page_mixin.dart';
import 'package:pure_live/pagination/models/base_controller_state.dart';

part 'hot_local_provider.g.dart';

@riverpod
class HotLocal extends _$HotLocal with BaseControllerMixin, LocalReactivePageMixin<LiveRoom> {
  Site? site;

  @override
  BasePagedState<LiveRoom> build(String siteId) {
    site = Sites.of(siteId);
    onExternalRefresh = () => loadData();
    return BasePagedState<LiveRoom>(
      controllerState: const BaseControllerState(),
      currentPage: firstPageKey,
      pageSize: defaultPageSize,
    );
  }

  Future<void> loadData() async {
    try {
      final rooms = await site!.liveSite.getRecommendRooms(page: 1, pageSize: state.pageSize);
      updateLocalReactivePool(rooms);
    } catch (_) {
      state = state.copyWith(items: const [], controllerState: state.controllerState.copyWith(pageEmpty: true));
    }
  }

  Future<void> loadFirstTime() async {
    if (state.items.isEmpty) {
      await loadData();
    }
  }

  Future<void> loadNextPage() async {
    await loadNextLocalPage();
  }
}
