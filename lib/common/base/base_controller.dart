import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';

class BaseController extends GetxController {
  /// 加载中，更新页面
  var pageLoadding = false.obs;

  /// 加载中,不会更新页面
  var loadding = false.obs;

  /// 空白页面
  var pageEmpty = false.obs;

  /// 页面错误
  var pageError = false.obs;

  /// 未登录
  var notLogin = false.obs;

  /// 错误信息
  var errorMsg = "".obs;

  /// 显示错误
  /// * [msg] 错误信息
  /// * [showPageError] 显示页面错误
  /// * 只在第一页加载错误时showPageError=true，后续页加载错误时使用Toast弹出通知
  void handleError(Object exception, {bool showPageError = false}) {
    var msg = exceptionToString(exception);

    if (showPageError) {
      pageError.value = true;
      errorMsg.value = msg;
    } else {
      SmartDialog.showToast(exceptionToString(msg));
    }
  }

  String exceptionToString(Object exception) {
    return exception.toString().replaceAll("Exception:", "");
  }

  void onLogin() {}
  void onLogout() {}
}

class BasePageController<T> extends BaseController {
  final ScrollController scrollController = ScrollController();
  final SettingsService settingsService = Get.find<SettingsService>();

  int currentPage = 1;
  int count = 0;
  int maxPage = 0;
  int pageSize = 30;
  var canLoadMore = false.obs;
  // 禁止到底部自动加载
  var stopLoadMore = true.obs;

  var autoRefresh = false.obs;

  var list = <T>[].obs;

  var _currentTimeStamp = 0;

  @override
  void onInit() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >= (scrollController.position.maxScrollExtent - 100.w)) {
        if (stopLoadMore.value) {
          loadData();
        }
      }
    });
    settingsService.routeChangeType.listen(listener);
    super.onInit();
  }

  Future refreshData() async {
    currentPage = 1;
    list.value = [];
    await loadData();
  }

  listener(event) {
    if (autoRefresh.value && event == RouteChangeType.pop) {
      settingsService.currentPlayListNodeIndex.value = 0;
      throttle(() {
        refreshData();
      });
    }
  }

  void throttle(Function func, [int delay = 1000]) {
    var now = DateTime.now().millisecondsSinceEpoch;
    if (now - _currentTimeStamp > delay) {
      _currentTimeStamp = now;
      func.call();
    }
  }

  Future loadData() async {
    try {
      if (loadding.value) return;
      loadding.value = true;
      pageError.value = false;
      pageEmpty.value = false;
      notLogin.value = false;
      pageLoadding.value = currentPage == 1;

      var result = await getData(currentPage, pageSize);
      //是否可以加载更多
      if (result.isNotEmpty) {
        currentPage++;
        canLoadMore.value = true;
        pageEmpty.value = false;
      } else {
        canLoadMore.value = false;
        if (currentPage == 1) {
          pageEmpty.value = true;
        }
      }
      // 赋值数据
      if (currentPage == 1) {
        list.value = result;
      } else {
        list.addAll(result);
      }
    } catch (e) {
      handleError(e, showPageError: currentPage == 1);
    } finally {
      loadding.value = false;
      pageLoadding.value = false;
    }
  }

  Future<List<T>> getData(int page, int pageSize) async {
    return [];
  }

  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void scrollToTopOrRefresh() {
    if (scrollController.offset > 0) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }
    refreshData();
  }

  @override
  void onClose() {
    autoRefresh.value = false;
    super.onClose();
  }
}
