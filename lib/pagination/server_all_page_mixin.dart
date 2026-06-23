import 'base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';

mixin ServerAllPageMixin<T> on BaseControllerMixin {
  BasePagedState<T> get state;
  set state(BasePagedState<T> value);

  Future<List<T>> fetchAllServerData();

  Future<void> refreshServerAllData() async {
    state = state.copyWith(
      allLocalItems: const [],
      items: const [],
      currentPage: 1,
      canLoadMore: false,
      controllerState: state.controllerState.copyWith(pageError: false),
    );
    await loadServerAllData(1);
  }

  Future<void> loadNextServerAllPage() async {
    if (state.controllerState.pageError || !state.canLoadMore) return;
    final nextPage = state.currentPage + 1;
    await loadServerAllData(nextPage);
  }

  Future<void> loadServerAllData(int pageKey) async {
    if (state.allLocalItems.isNotEmpty) {
      _processServerAllDistribution(state.allLocalItems, pageKey);
      return;
    }

    final isNetworkSafe = await checkNetworkBeforeRequest();
    if (!isNetworkSafe) {
      state = state.copyWith(controllerState: controllerState);
      return;
    }

    try {
      final List<T> fetchedData = await fetchAllServerData();
      _processServerAllDistribution(fetchedData, pageKey);
    } catch (e) {
      handleError(e);
      state = state.copyWith(controllerState: controllerState);
    }
  }

  void _processServerAllDistribution(List<T> allItems, int targetPage) {
    final int pageSize = state.pageSize;

    if (allItems.isEmpty) {
      state = state.copyWith(
        allLocalItems: allItems,
        items: const [],
        currentPage: 1,
        canLoadMore: false,
        totalCount: 0,
        controllerState: state.controllerState.copyWith(pageEmpty: true, pageError: false),
      );
      return;
    }

    int startIndex = (targetPage - 1) * pageSize;

    if (startIndex >= allItems.length) {
      startIndex = 0;
      targetPage = 1;
    }

    int endIndex = startIndex + pageSize;
    if (endIndex > allItems.length) endIndex = allItems.length;

    final nextChunk = allItems.sublist(startIndex, endIndex);

    state = state.copyWith(
      allLocalItems: allItems,
      items: targetPage == 1 ? nextChunk : [...state.items, ...nextChunk],
      currentPage: targetPage,
      canLoadMore: endIndex < allItems.length,
      totalCount: allItems.length,
      controllerState: state.controllerState.copyWith(pageEmpty: false, pageError: false),
    );
  }
}
