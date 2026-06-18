import 'dart:async';
import 'package:pure_live/common/index.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:pure_live/common/base/base_page_scroll_bone_tv.dart';

abstract class ServerRemotePageController<T> extends BaseTvPageScrollBone<T> {
  final Map<int, List<T>> _pageCache = {};
  int _virtualNetworkPage = 1;

  Future<List<T>> fetchNetworkData(int page, int pageSize);

  @override
  Future<void> refreshData() async {
    currentPage = 1;
    _virtualNetworkPage = 1;
    _pageCache.clear();
    list.clear();
    await loadData();
  }

  @override
  Future<void> loadData() async {
    if (loadding.value) return;
    totalCount.value = null;
    final bool isNetworkSafe = await checkNetworkBeforeRequest();
    if (!isNetworkSafe) {
      finishRefreshControllers(IndicatorResult.fail);
      return;
    }
    try {
      loadding.value = true;
      pageError.value = false;
      pageEmpty.value = false;
      notLogin.value = false;
      if (list.isEmpty) pageLoadding.value = true;
      List<T> combinedResult = [];
      final int sizeToFetch = pageSize.value;
      while (combinedResult.length < sizeToFetch) {
        final result = await fetchNetworkData(_virtualNetworkPage, sizeToFetch);
        if (result.isEmpty) break;
        combinedResult.addAll(result);
        _virtualNetworkPage++;
      }
      if (currentPage == 1) {
        list.assignAll(combinedResult);
      } else {
        list.addAll(combinedResult);
      }
      canLoadMore.value = combinedResult.length >= pageSize.value;
      pageEmpty.value = list.isEmpty;
      finishRefreshControllers(canLoadMore.value ? IndicatorResult.success : IndicatorResult.noMore);
    } catch (e) {
      handleError(e, showPageError: list.isEmpty);
      finishRefreshControllers(IndicatorResult.fail);
    } finally {
      loadding.value = false;
      pageLoadding.value = false;
    }
  }

  Future<void> loadMoreData() async {
    currentPage++;
    await loadData();
  }
}
