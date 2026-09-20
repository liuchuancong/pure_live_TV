import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/features/wallpaper/wallpaper_paging.dart';
import 'package:pure_live/shared/pagination/models/paging_param.dart';
import 'package:pure_live/shared/pagination/paging_core.dart';
import 'package:pure_live/services/background_config/local/wallpaper_video.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:dio/dio.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/wallpaper/system_wallpaper.dart';

/// The wallpaper sequence shared by the preview and immersive pages: paging
/// with prefetch for directory sources, random-image fetches for API sources,
/// and applying the current item. Index and caches live here, so both pages
/// advance one sequence.
class WallpaperSequence {
  WallpaperSequence({required this.args, required this.ref, int initialIndex = 0})
    : index = initialIndex;

  final WallpaperPreviewArgs args;
  final WidgetRef ref;

  static const BackgroundItem emptyItem = BackgroundItem(file: '');

  /// Directory mode: current position.
  int index;

  /// API mode: fetched bytes and load state.
  Uint8List? apiBytes;
  bool apiLoading = false;

  /// The list has not grown yet when the next page is requested; step forward
  /// once it does.
  bool _waitingForPage = false;

  PagingParam<BackgroundItem>? _param;

  bool get isVideo => !args.isApiMode && args.kind == BackgroundKind.video;

  List<BackgroundItem> get _items => args.isApiMode ? const <BackgroundItem>[] : _resolveItems();

  /// Items for the page to render; directory mode triggers prefetch here.
  List<BackgroundItem> get visibleItems => _items;

  BackgroundItem itemAt(List<BackgroundItem> items) {
    if (items.isEmpty) return emptyItem;
    return items[index.clamp(0, items.length - 1)];
  }

  /// The item to show now (resolves the directory list).
  BackgroundItem get current => itemAt(_items);

  /// Advances to a newly arrived item; returns whether anything changed.
  bool consumePendingAdvance(List<BackgroundItem> items) {
    if (!_waitingForPage || index + 1 >= items.length) return false;
    _waitingForPage = false;
    index += 1;
    return true;
  }

  /// Directory items: the grid page's paging core, prefetching near the end.
  List<BackgroundItem> _resolveItems() {
    if (args.isApiMode) return const <BackgroundItem>[];
    final catalog = ref.watch(backgroundCatalogProvider);
    final source = catalog.sourceById(args.sourceId!);
    if (source == null) return const <BackgroundItem>[];
    final category = _pickCategory(source, args.categoryId);
    if (category == null) return const <BackgroundItem>[];

    final param = wallpaperPagingParam(source, category);
    _param = param;
    final state = ref.watch(pagingCoreProvider(param));
    if (state.canLoadMore && !state.controllerState.loading && index >= state.items.length - 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) => prefetch(state.items));
    }
    return state.items;
  }

  static BackgroundCategory? _pickCategory(BackgroundSource source, String? wanted) {
    final categories = source.visibleCategories;
    if (categories.isEmpty) return null;
    if (wanted == null) return categories.first;
    for (final category in categories) {
      if (category.id == wanted) return category;
    }
    return categories.first;
  }

  void prefetch([List<BackgroundItem>? items, bool force = false]) {
    final param = _param;
    if (param == null) return;
    final resolved = items ?? ref.read(pagingCoreProvider(param)).items;
    final state = ref.read(pagingCoreProvider(param));
    if (!state.canLoadMore || state.controllerState.loading) return;
    if (!force && index < resolved.length - 3) return;
    ref.read(pagingCoreProvider(param).notifier).loadNextPage();
  }

  /// Next item; API mode fetches another random image.
  Future<void> next() async {
    if (args.isApiMode) {
      if (!apiLoading) await fetchApiImage();
      return;
    }
    final items = _resolveItems();
    if (items.length < 2) return;

    final int target = index + 1;
    if (target < items.length) {
      index = target;
      prefetch(items);
      return;
    }

    final param = _param;
    if (param != null && ref.read(pagingCoreProvider(param)).canLoadMore) {
      _waitingForPage = true;
      prefetch(items, true);
      return;
    }
    index = 0;
  }

  void previous() {
    if (args.isApiMode) return;
    final items = _resolveItems();
    if (items.length < 2) return;
    index = index <= 0 ? items.length - 1 : index - 1;
  }

  /// API mode: fetches a random image; returns whether it arrived.
  Future<bool> fetchApiImage() async {
    final source = args.apiSource;
    if (source == null) return false;
    apiLoading = true;
    try {
      final bytes = await fetchRandomImage(source);
      if (bytes != null) apiBytes = bytes;
      return bytes != null;
    } catch (_) {
      return false;
    } finally {
      apiLoading = false;
    }
  }

  /// Applies the current item as the app background. Throws on failure and on
  /// incomplete gradient data; the page turns it into a toast.
  Future<void> applyCurrent() async {
    final bg = SettingsService.to.bg;
    if (args.isApiMode) {
      final bytes = apiBytes;
      if (bytes == null) throw StateError('no image bytes');
      bg.setNetworkImageBytes(bytes);
      return;
    }
    final item = current;
    switch (args.kind!) {
      case BackgroundKind.image:
        bg.setNetworkImage(item.file);
      case BackgroundKind.video:
        await _applyVideo(item);
      case BackgroundKind.gradient:
        final colors = <Color>[
          for (final stop in item.gradient ?? const <BackgroundGradientStop>[]) ColorUtil.hexToColor(stop.color),
        ];
        if (colors.length < 2) throw StateError('incomplete gradient');
        bg.setGradient(colors);
    }
  }

  /// Writes the system wallpaper; true means the OS confirm screen is
  /// waiting. Throws with a reason on failure.
  Future<bool> applyToSystemWallpaper() async {
    if (args.isApiMode) {
      final bytes = apiBytes;
      if (bytes == null) throw StateError('no image bytes');
      await _setSystemImage(bytes);
      return false;
    }

    final item = current;
    switch (args.kind!) {
      case BackgroundKind.gradient:
        // A gradient has no image for the wallpaper API to write.
        throw StateError('gradient');
      case BackgroundKind.video:
        String? localPath;
        try {
          localPath = await WallpaperVideoStore.download(item.file);
        } catch (_) {
          localPath = null;
        }
        final String? videoFailure = await SystemWallpaper.setVideo(filePath: localPath, url: item.file);
        if (videoFailure != null) throw StateError(videoFailure);
        return true;
      case BackgroundKind.image:
        final response = await Dio(
          BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 5)),
        ).get<List<int>>(item.file, options: Options(responseType: ResponseType.bytes));
        final data = response.data;
        if (data == null) throw StateError('download_failed');
        await _setSystemImage(Uint8List.fromList(data));
        return false;
    }
  }

  Future<void> _setSystemImage(Uint8List bytes) async {
    final String? failure = await SystemWallpaper.setImage(bytes);
    if (failure != null) throw StateError(failure);
  }

  Future<void> _applyVideo(BackgroundItem item) async {
    final bg = SettingsService.to.bg;
    try {
      final String path = await WallpaperVideoStore.download(item.file);
      bg.setLocalVideo(path);
    } catch (_) {
      // Falls back to streaming when the download fails.
      bg.setNetworkVideo(item.file);
    }
  }
}
