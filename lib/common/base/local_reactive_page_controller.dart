import 'dart:async';
import 'package:pure_live/common/index.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:pure_live/common/base/base_page_scroll_bone_tv.dart';

abstract class LocalReactivePageController<T> extends BaseTvPageScrollBone<T> {
  final List<T> _localRawPool = [];
  void Function()? onExternalRefresh;

  void updateLocalReactivePool(List<T> freshData) {
    _localRawPool.clear();
    _localRawPool.addAll(freshData);
    currentPage = 1;
    _processDataDistribution();
  }

  @override
  Future<void> refreshData() async {
    onExternalRefresh?.call();
    currentPage = 1;
    _processDataDistribution();
  }

  @override
  Future<void> goToPage(int page) async {}

  @override
  void setPageSize(int? newSize) {}

  @override
  Future<void> loadData() async {
    _processDataDistribution();
  }

  void _processDataDistribution() {
    totalCount.value = _localRawPool.length;
    list.assignAll(_localRawPool);
    canLoadMore.value = false;
    pageEmpty.value = list.isEmpty;
    finishRefreshControllers(IndicatorResult.noMore);
    scrollToTopImmediate();
  }
}
