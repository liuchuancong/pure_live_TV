import 'dart:async';
import 'package:pure_live/common/index.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:pure_live/common/base/base_page_scroll_bone_tv.dart';

abstract class ServerFixedPageController<T> extends BaseTvPageScrollBone<T> {
  final int fixedServerPageSize;
  final Map<int, List<T>> _bigPageCache = {};

  ServerFixedPageController({required this.fixedServerPageSize});

  Future<List<T>> fetchFixedNetworkData(int bigPage, int fixedSize);

  @override
  Future<void> refreshData() async {
    _bigPageCache.clear();
    currentPage = 1;
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
    final int targetOffset = (currentPage - 1) * pageSize.value;
    try {
      loadding.value = true;
      pageError.value = false;
      pageEmpty.value = false;
      notLogin.value = false;
      if (list.isEmpty) pageLoadding.value = true;
      List<T> combinedData = [];
      int currentFetchOffset = targetOffset;
      while (currentFetchOffset < targetOffset + pageSize.value) {
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
        final int needTake = targetOffset + pageSize.value - currentFetchOffset;
        final int availableCount = bigPageData.length - innerStart;
        final int takeCount = needTake < availableCount ? needTake : availableCount;
        combinedData.addAll(bigPageData.sublist(innerStart, innerStart + takeCount));
        currentFetchOffset += takeCount;
        if (bigPageData.length < fixedServerPageSize) break;
      }
      if (currentPage == 1) {
        list.assignAll(combinedData);
      } else {
        list.addAll(combinedData);
      }
      canLoadMore.value = combinedData.length >= pageSize.value;
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

  @override
  Future<void> loadMoreData() async {
    currentPage++;
    await loadData();
  }
}
