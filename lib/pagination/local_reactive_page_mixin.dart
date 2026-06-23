import 'base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';

mixin LocalReactivePageMixin<T> on BaseControllerMixin {
  BasePagedState<T> get state;
  set state(BasePagedState<T> value);

  int get firstPageKey => 1;
  int get defaultPageSize => 20;

  void Function()? onExternalRefresh;

  void updateLocalReactivePool(List<T> freshData) {
    final int pageSize = state.pageSize;
    final int targetPage = 1;
    final int endIndex = freshData.length > pageSize ? pageSize : freshData.length;

    final chunkItems = freshData.sublist(0, endIndex);

    state = state.copyWith(
      allLocalItems: freshData,
      items: chunkItems,
      currentPage: targetPage,
      canLoadMore: freshData.length > endIndex,
      totalCount: freshData.length,
      controllerState: state.controllerState.copyWith(
        pageLoading: false,
        pageEmpty: chunkItems.isEmpty,
        pageError: false,
        errorMsg: "",
      ),
    );
  }

  Future<void> refreshLocalData() async {
    state = state.copyWith(
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false, pageEmpty: false),
    );
    onExternalRefresh?.call();
    _processTvDataDistribution(state.allLocalItems, 1);
  }

  Future<void> loadNextLocalPage() async {
    if (state.controllerState.pageError || !state.canLoadMore) return;
    final nextPage = state.currentPage + 1;
    _processTvDataDistribution(state.allLocalItems, nextPage);
  }

  void _processTvDataDistribution(List<T> pool, int targetPage) {
    final int pageSize = state.pageSize;

    if (pool.isEmpty) {
      state = state.copyWith(
        items: const [],
        currentPage: 1,
        canLoadMore: false,
        totalCount: 0,
        controllerState: state.controllerState.copyWith(pageLoading: false, pageEmpty: true, pageError: false),
      );
      return;
    }

    int startIndex = (targetPage - 1) * pageSize;

    if (startIndex >= pool.length) {
      final int calculatedMaxPage = (pool.length / pageSize).ceil();
      startIndex = (calculatedMaxPage - 1) * pageSize;
      targetPage = calculatedMaxPage;
    }

    int endIndex = startIndex + pageSize;
    if (endIndex > pool.length) endIndex = pool.length;

    final nextChunk = pool.sublist(startIndex, endIndex);

    state = state.copyWith(
      items: targetPage == 1 ? nextChunk : [...state.items, ...nextChunk],
      currentPage: targetPage,
      canLoadMore: endIndex < pool.length,
      totalCount: pool.length,
      controllerState: state.controllerState.copyWith(pageLoading: false, pageEmpty: false, pageError: false),
    );
  }
}
