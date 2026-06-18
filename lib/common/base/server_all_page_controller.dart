import 'dart:async';
import 'package:pure_live/common/index.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:pure_live/common/base/base_page_scroll_bone_tv.dart';

abstract class ServerAllPageController<T> extends BaseTvPageScrollBone<T> {
  List<T>? _rawAllData;

  @override
  Future<void> refreshData() async {
    _rawAllData = null;
    currentPage = 1;
    list.clear();
    canLoadMore.value = false;
    await loadData();
  }

  Future<List<T>> fetchAllServerData();

  @override
  Future<void> loadData() async {
    if (loadding.value) return;
    if (_rawAllData != null) {
      list.assignAll(_rawAllData!);
      pageEmpty.value = list.isEmpty;
      finishRefreshControllers(IndicatorResult.success);
      return;
    }
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
      pageLoadding.value = true;
      _rawAllData = await fetchAllServerData();
      list.assignAll(_rawAllData!);
      pageEmpty.value = list.isEmpty;
      canLoadMore.value = false;
      finishRefreshControllers(IndicatorResult.noMore);
    } catch (e) {
      handleError(e, showPageError: list.isEmpty);
      finishRefreshControllers(IndicatorResult.fail);
    } finally {
      loadding.value = false;
      pageLoadding.value = false;
    }
  }
}
