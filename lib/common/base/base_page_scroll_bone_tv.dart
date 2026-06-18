import 'dart:async';
import 'package:pure_live/common/index.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:pure_live/common/base/base_controller.dart';

abstract class BaseTvPageScrollBone<T> extends BaseController {
  final ScrollController scrollController = ScrollController();
  final EasyRefreshController easyRefreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );
  int currentPage = 1;
  final pageSize = 20.obs;
  final canLoadMore = false.obs;
  final list = <T>[].obs;
  final totalCount = Rxn<int>();
  final showBackToTop = false.obs;

  BaseTvPageScrollBone() {
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset;
    if (offset > 400 && !showBackToTop.value) {
      showBackToTop.value = true;
    } else if (offset <= 400 && showBackToTop.value) {
      showBackToTop.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    easyRefreshController.dispose();
    super.onClose();
  }

  void scrollToTopImmediate() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void finishRefreshControllers(IndicatorResult result) {
    easyRefreshController.finishRefresh(
      result == IndicatorResult.fail ? IndicatorResult.fail : IndicatorResult.success,
    );
    easyRefreshController.finishLoad(result);
  }

  void scrollToTopOrRefresh() {
    if (!scrollController.hasClients) return;
    if (scrollController.offset > 0) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else {
      easyRefreshController.callRefresh();
    }
  }

  Future<void> loadMoreData() async {
    currentPage++;
    await loadData();
  }

  Future<void> loadData();
  Future<void> refreshData();
}
