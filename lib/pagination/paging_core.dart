import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pure_live/utils/log.dart';
import 'package:pure_live/pagination/type_def/fun.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/pagination/models/paging_model.dart';
import 'package:pure_live/pagination/models/paging_param.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:pure_live/pagination/models/base_controller_state.dart';

part 'paging_core.g.dart';

@riverpod
class PagingCore<T> extends _$PagingCore<T> {
  late PagingParam<T> param;
  late final PagingMode mode;
  late final int fixedServerPageSize;
  FetchRemote<T>? fetchRemote;
  FetchAllData<T>? fetchAll;
  FetchFixedSize<T>? fetchFixed;
  VoidCallback? onLocalSourceUpdate;

  static const int firstPageKey = 1;

  final ScrollController scrollController = ScrollController();

  final Map<int, List<T>> _bigPageCache = {};

  static const int _maxCachePages = 20;

  bool _loadingMore = false;

  int _requestToken = 0;

  @override
  BasePagedState<T> build(PagingParam<T> pParam) {
    if (pParam.keepAlive) {
      ref.keepAlive();
    }
    param = pParam;
    mode = param.mode;
    fixedServerPageSize = param.fixedServerSize;
    fetchRemote = param.fetchRemote;
    fetchAll = param.fetchAll;
    fetchFixed = param.fetchFixed;
    onLocalSourceUpdate = param.localRefresh;

    ref.onDispose(() {
      scrollController.dispose();
      _bigPageCache.clear();
    });
    Future.microtask(() => refresh());
    return BasePagedState<T>(controllerState: const BaseControllerState(pageLoading: true), pageSize: param.pageSize);
  }

  Future<bool> checkNetworkBeforeRequest() async {
    try {
      final result = await Connectivity().checkConnectivity();

      if (result.isEmpty || result.contains(ConnectivityResult.none)) {
        handleError("network_disconnected");
        return false;
      }
    } catch (_) {
      return true;
    }

    return true;
  }

  String exceptionToString(Object exception) {
    if (exception is String) return exception;

    final msg = exception.toString().replaceAll("Exception:", "").trim();

    return msg.isEmpty ? "未知错误，请重试" : msg;
  }

  void handleError(Object exception) {
    String msg;
    if (exception is SocketException || exception is TimeoutException) {
      msg = "网络连接失败，请检查网络";
    } else if (exception is HttpException) {
      msg = "服务器异常";
    } else {
      msg = exceptionToString(exception);
    }

    final exceptionStr = exception.toString().toLowerCase();

    final isLoginIssue =
        exceptionStr.contains("loginrequired") ||
        exceptionStr.contains("unauthorized") ||
        exceptionStr.contains("未登录") ||
        exception.toString().contains("NoSuchMethodError") && exception.toString().contains("'[]'");
    Log.d(isLoginIssue.toString());
    state = state.copyWith(
      controllerState: state.controllerState.copyWith(
        errorMsg: msg,
        notLogin: isLoginIssue,
        pageError: !isLoginIssue,
        pageLoading: false,
      ),
    );
  }

  void onLogin() {
    state = state.copyWith(controllerState: state.controllerState.copyWith(notLogin: false));
  }

  void onLogout() {
    state = state.copyWith(controllerState: state.controllerState.copyWith(notLogin: true));
  }

  Future<void> refresh() async {
    _requestToken++;
    state = state.copyWith(controllerState: state.controllerState.copyWith(pageLoading: true));
    switch (mode) {
      case PagingMode.serverRemote:
        return _refreshRemote();
      case PagingMode.serverFixedSize:
        return _refreshFixed();
      case PagingMode.serverAll:
        return _refreshServerAll();
      case PagingMode.localReactive:
        return _refreshLocalReactive();
    }
  }

  Future<void> _loadLocalNext(int targetPage) async {
    final token = _requestToken;
    if (token != _requestToken) return;
    _sliceLocalData(state.allLocalItems, targetPage);
  }

  Future<void> loadNextPage() async {
    if (_loadingMore) return;

    if (state.controllerState.pageError) return;

    if (!state.canLoadMore) return;

    _loadingMore = true;
    state = state.copyWith(controllerState: state.controllerState.copyWith(loading: true));
    try {
      final nextPage = state.currentPage + 1;

      switch (mode) {
        case PagingMode.serverRemote:
          await _loadRemote(nextPage);
          break;

        case PagingMode.serverFixedSize:
          await _loadFixed(nextPage);
          break;

        case PagingMode.serverAll:
          await _loadServerAll(nextPage);
          break;

        case PagingMode.localReactive:
          await _loadLocalNext(nextPage);
          break;
      }
    } finally {
      _loadingMore = false;
      state = state.copyWith(controllerState: state.controllerState.copyWith(loading: false));
    }
  }

  void updateLocalPool(List<T> freshData) {
    final pageSize = state.pageSize;

    final end = freshData.length > pageSize ? pageSize : freshData.length;

    final chunk = freshData.sublist(0, end);

    state = state.copyWith(
      allLocalItems: freshData,
      items: chunk,
      currentPage: firstPageKey,
      canLoadMore: freshData.length > end,
      totalCount: freshData.length,
      controllerState: state.controllerState.copyWith(
        pageLoading: false,
        pageEmpty: chunk.isEmpty,
        pageError: false,
        errorMsg: "",
      ),
    );
  }

  void scrollToTopImmediate() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void scrollToTop() {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void _putCache(int page, List<T> data) {
    if (_bigPageCache.length >= _maxCachePages && !_bigPageCache.containsKey(page)) {
      _bigPageCache.remove(_bigPageCache.keys.first);
    }

    _bigPageCache[page] = data;
  }

  Future<void> _refreshLocalReactive() async {
    state = state.copyWith(
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false, pageEmpty: false),
    );

    onLocalSourceUpdate?.call();

    _sliceLocalData(state.allLocalItems, firstPageKey);
  }

  void _sliceLocalData(List<T> pool, int targetPage) {
    final ps = state.pageSize;

    if (pool.isEmpty) {
      state = state.copyWith(
        items: const [],
        currentPage: firstPageKey,
        canLoadMore: false,
        totalCount: 0,
        controllerState: state.controllerState.copyWith(pageLoading: false, pageEmpty: true, pageError: false),
      );

      return;
    }

    int start = (targetPage - 1) * ps;

    if (start >= pool.length) {
      final maxPage = (pool.length / ps).ceil();

      targetPage = maxPage;

      start = (maxPage - 1) * ps;
    }

    int end = start + ps;

    if (end > pool.length) {
      end = pool.length;
    }

    final chunk = pool.sublist(start, end);

    state = state.copyWith(
      items: targetPage == firstPageKey ? chunk : [...state.items, ...chunk],
      currentPage: targetPage,
      canLoadMore: end < pool.length,
      totalCount: pool.length,
      controllerState: state.controllerState.copyWith(pageLoading: false, pageEmpty: false, pageError: false),
    );
  }

  Future<void> _refreshServerAll() async {
    state = state.copyWith(
      allLocalItems: [],
      items: [],
      currentPage: firstPageKey,
      canLoadMore: false,
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false),
    );

    await _loadServerAll(firstPageKey);
  }

  Future<void> _loadServerAll(int pageKey) async {
    if (state.allLocalItems.isNotEmpty) {
      _sliceLocalData(state.allLocalItems, pageKey);
      return;
    }

    final token = _requestToken;

    final isNetworkOk = await checkNetworkBeforeRequest();

    if (!isNetworkOk) return;

    try {
      final all = await fetchAll!();

      if (token != _requestToken) {
        return;
      }

      state = state.copyWith(allLocalItems: all);

      _sliceLocalData(all, pageKey);
    } catch (e) {
      if (token != _requestToken) {
        return;
      }

      handleError(e);
    }
  }

  Future<void> _refreshRemote() async {
    state = state.copyWith(
      items: [],
      currentPage: firstPageKey,
      canLoadMore: false,
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false),
    );

    await _loadRemote(firstPageKey);
  }

  Future<void> _loadRemote(int pageKey) async {
    final token = _requestToken;

    final isNetworkOk = await checkNetworkBeforeRequest();

    if (!isNetworkOk) return;

    try {
      final list = await fetchRemote!(pageKey, state.pageSize);

      if (token != _requestToken) {
        return;
      }

      final hasMore = list.length >= state.pageSize;

      state = state.copyWith(
        items: pageKey == firstPageKey ? list : [...state.items, ...list],
        currentPage: pageKey,
        canLoadMore: hasMore,
        controllerState: state.controllerState.copyWith(
          pageLoading: false,
          pageEmpty: pageKey == firstPageKey && list.isEmpty,
          pageError: false,
          errorMsg: "",
        ),
      );
    } catch (e) {
      if (token != _requestToken) {
        return;
      }

      handleError(e);
    }
  }

  Future<void> _refreshFixed() async {
    _bigPageCache.clear();

    state = state.copyWith(
      items: [],
      currentPage: firstPageKey,
      canLoadMore: false,
      controllerState: state.controllerState.copyWith(pageLoading: true, pageError: false),
    );

    await _loadFixed(firstPageKey);
  }

  Future<void> _loadFixed(int pageKey) async {
    final token = _requestToken;

    final isNetworkOk = await checkNetworkBeforeRequest();

    if (!isNetworkOk) return;

    final ps = state.pageSize;

    final prevPage = state.currentPage;

    final globalStart = (pageKey - 1) * ps;

    final globalEnd = globalStart + ps;

    final List<T> combined = [];

    try {
      int offset = globalStart;

      while (offset < globalEnd) {
        final bigPage = (offset ~/ fixedServerPageSize) + 1;

        List<T> bigData;

        if (_bigPageCache.containsKey(bigPage)) {
          bigData = _bigPageCache[bigPage]!;
        } else {
          bigData = await fetchFixed!(bigPage, fixedServerPageSize);

          _putCache(bigPage, bigData);
        }

        if (token != _requestToken) {
          return;
        }

        if (bigData.isEmpty) {
          break;
        }

        final innerStart = offset % fixedServerPageSize;

        if (innerStart >= bigData.length) {
          break;
        }

        final remainNeed = globalEnd - offset;

        final remainData = bigData.length - innerStart;

        final take = remainNeed < remainData ? remainNeed : remainData;

        combined.addAll(bigData.sublist(innerStart, innerStart + take));

        offset += take;

        if (bigData.length < fixedServerPageSize) {
          break;
        }
      }

      if (token != _requestToken) {
        return;
      }

      state = state.copyWith(
        items: pageKey == firstPageKey ? combined : [...state.items, ...combined],
        currentPage: pageKey,
        canLoadMore: combined.length >= ps,
        controllerState: state.controllerState.copyWith(
          pageLoading: false,
          pageEmpty: pageKey == firstPageKey && combined.isEmpty,
          pageError: false,
          errorMsg: "",
        ),
      );
    } catch (e) {
      if (token != _requestToken) {
        return;
      }
      state = state.copyWith(
        currentPage: prevPage,
        controllerState: state.controllerState.copyWith(pageLoading: false),
      );
      handleError(e);
    }
  }
}
