import 'base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';

mixin ServerRemotePageMixin<T> on BaseControllerMixin {
  BasePagedState<T> get state;
  set state(BasePagedState<T> value);

  int get firstPageKey => 1;
  int get defaultPageSize => 20;

  Future<List<T>> fetchServerRemoteData(int pageKey, int pageSize);

  Future<void> refreshRemoteData() async {
    state = state.copyWith(
      items: const [],
      currentPage: 1,
      canLoadMore: false,
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false, pageEmpty: false),
    );
    await loadRemoteData(1);
  }

  Future<void> loadNextRemotePage() async {
    if (state.controllerState.pageError || !state.canLoadMore) return;
    final nextPage = state.currentPage + 1;
    await loadRemoteData(nextPage);
  }

  Future<void> loadRemoteData(int pageKey) async {
    final int pageSize = state.pageSize;

    if (pageKey == firstPageKey) {
      state = state.copyWith(
        controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false, pageEmpty: false),
      );
    }

    final isNetworkSafe = await checkNetworkBeforeRequest();
    if (!isNetworkSafe) {
      state = state.copyWith(controllerState: controllerState);
      return;
    }

    try {
      final List<T> newItems = await fetchServerRemoteData(pageKey, pageSize);
      final bool hasMore = newItems.length >= pageSize;

      state = state.copyWith(
        items: pageKey == 1 ? newItems : [...state.items, ...newItems],
        currentPage: pageKey,
        canLoadMore: hasMore,
        controllerState: state.controllerState.copyWith(
          pageLoading: false,
          pageEmpty: (pageKey == 1 && newItems.isEmpty),
          pageError: false,
        ),
      );
    } catch (e) {
      if (e.toString().contains("NoSuchMethodError") && e.toString().contains("'[]'")) {
        handleError("loginRequired");
      } else {
        handleError(e);
      }
      state = state.copyWith(
        controllerState: controllerState.copyWith(pageLoading: false),
      );
    }
  }
}
