import 'base_controller_mixin.dart';
import 'package:flutter/material.dart';

mixin BasePageScrollMixin<T> on BaseControllerMixin {
  final ScrollController scrollController = ScrollController();

  int get firstPageKey => 1;
  int get defaultPageSize => 20;

  Future<List<T>> fetchData(int pageKey);

  void initScrollAndState() {
    (this as dynamic).ref.onDispose(() {
      scrollController.dispose();
    });
  }

  Future<void> refreshData() async {
    final dynamic self = this;
    self.state = self.state.copyWith(
      currentPage: firstPageKey,
      controllerState: self.state.controllerState.copyWith(pageError: false),
    );
    await loadPage(firstPageKey);
  }

  Future<void> loadNextPage() async {
    final dynamic self = this;
    if (self.state.controllerState.pageError || !self.state.canLoadMore) return;
    final nextPage = self.state.currentPage + 1;
    await loadPage(nextPage);
  }

  Future<void> loadPage(int pageKey) async {
    final dynamic self = this;
    final isNetworkOk = await checkNetworkBeforeRequest();
    if (!isNetworkOk) {
      self.state = self.state.copyWith(controllerState: controllerState);
      return;
    }

    try {
      final newItems = await fetchData(pageKey);
      final hasMore = newItems.length >= self.state.pageSize;

      self.state = self.state.copyWith(
        items: pageKey == firstPageKey ? newItems : [...self.state.items, ...newItems],
        currentPage: pageKey,
        canLoadMore: hasMore,
        controllerState: self.state.controllerState.copyWith(pageError: false, errorMsg: ""),
      );
    } catch (e) {
      handleError(e);
      self.state = self.state.copyWith(controllerState: controllerState);
    }
  }

  void scrollToTopImmediate() {
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }
  }
}
