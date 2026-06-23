import 'base_controller_mixin.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';

mixin ServerFixedPageMixin<T> on BaseControllerMixin {
  BasePagedState<T> get state;
  set state(BasePagedState<T> value);

  int get firstPageKey => 1;
  int get defaultPageSize => 20;

  int get fixedServerPageSize;

  final Map<int, List<T>> _bigPageCache = {};

  Future<List<T>> fetchFixedNetworkData(int bigPage, int fixedSize);

  Future<void> refreshFixedData() async {
    _bigPageCache.clear();
    state = state.copyWith(
      items: const [],
      currentPage: 1,
      canLoadMore: false,
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false, pageEmpty: false),
    );
    await loadFixedData(1);
  }

  Future<void> loadNextFixedPage() async {
    if (state.controllerState.pageError || !state.canLoadMore) return;
    final nextPage = state.currentPage + 1;
    await loadFixedData(nextPage);
  }

  Future<void> loadFixedData(int pageKey) async {
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

    final int previousPageSnapshot = state.currentPage;
    final int currentGlobalStart = (pageKey - 1) * pageSize;
    final int currentGlobalEnd = currentGlobalStart + pageSize;

    try {
      List<T> combinedData = [];
      int currentFetchOffset = currentGlobalStart;

      while (currentFetchOffset < currentGlobalEnd) {
        final int serverBigPage = (currentFetchOffset ~/ fixedServerPageSize) + 1;
        List<T> bigPageData;

        if (_bigPageCache.containsKey(serverBigPage)) {
          bigPageData = _bigPageCache[serverBigPage]!;
        } else {
          bigPageData = await fetchFixedNetworkData(serverBigPage, fixedServerPageSize);
          _bigPageCache[serverBigPage] = bigPageData;
        }

        if (bigPageData.isEmpty) break;

        final int innerStart = currentFetchOffset % fixedServerPageSize;
        if (innerStart >= bigPageData.length) break;

        final int neededCount = currentGlobalEnd - currentFetchOffset;
        final int availableCount = bigPageData.length - innerStart;
        final int takeCount = neededCount < availableCount ? neededCount : availableCount;

        combinedData.addAll(bigPageData.sublist(innerStart, innerStart + takeCount));
        currentFetchOffset += takeCount;

        if (bigPageData.length < fixedServerPageSize) break;
      }

      if (combinedData.isEmpty && pageKey > 1) {
        state = state.copyWith(canLoadMore: false);
        return;
      }

      state = state.copyWith(
        items: pageKey == 1 ? combinedData : [...state.items, ...combinedData],
        currentPage: pageKey,
        canLoadMore: combinedData.length >= pageSize,
        controllerState: state.controllerState.copyWith(
          pageLoading: false,
          pageEmpty: (pageKey == 1 && combinedData.isEmpty),
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
        currentPage: previousPageSnapshot,
        controllerState: controllerState.copyWith(pageLoading: false),
      );
    }
  }
}
