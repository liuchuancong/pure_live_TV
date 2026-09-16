import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_display_options.dart';
import 'package:pure_live/features/wallpaper/wallpaper_image.dart';
import 'package:pure_live/features/wallpaper/wallpaper_paging.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/pagination/models/paging_param.dart';
import 'package:pure_live/shared/pagination/paging_core.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// What one button in the preview's action bar does.
enum _PreviewActionKind { prev, next, fresh, fit, mask, apply }

/// One entry of the preview's action bar.
class _PreviewAction {
  const _PreviewAction({
    required this.kind,
    required this.icon,
    required this.label,
    this.busy = false,
    this.primary = false,
  });

  final _PreviewActionKind kind;
  final IconData icon;
  final String label;
  final bool busy;

  /// The commit button, drawn filled so it reads as the primary action.
  final bool primary;
}

/// Fullscreen preview of exactly one wallpaper.
///
/// Everything is operated through the button bar: `←`/`→` move the highlight
/// between the buttons and `OK` runs the highlighted one. There is no second
/// key mode and no page-level d-pad traversal — the bar is wrapped in an
/// [ExcludeFocus] and the highlight is computed here, because the arrows are
/// what the user needs to reach 设为背景 and the other options.
///
/// In catalog mode the page watches the same paging core as the grid, so 上一个
/// / 下一个 walk straight past the end of the loaded page: the next page is
/// fetched in the background *before* it is needed, and the picture advances as
/// soon as it arrives.
class WallpaperPreviewPage extends ConsumerStatefulWidget {
  const WallpaperPreviewPage({super.key, required this.args});

  final WallpaperPreviewArgs args;

  @override
  ConsumerState<WallpaperPreviewPage> createState() =>
      _WallpaperPreviewPageState();
}

class _WallpaperPreviewPageState extends ConsumerState<WallpaperPreviewPage> {
  final FocusNode _pageFocus = FocusNode(debugLabel: 'wallpaper-preview');

  /// Catalog mode: position in the paged list.
  int _index = 0;

  /// API mode: the downloaded picture and its fetch state.
  Uint8List? _apiBytes;
  bool _apiLoading = false;
  bool _applying = false;

  /// Which bottom button is highlighted.
  int _actionIndex = 0;

  /// Set when the user asked for the next entry while the next page was still
  /// being fetched; the advance happens as soon as the list grows.
  bool _waitingForPage = false;

  /// The paging parameters in force, kept for the key handlers.
  PagingParam<BackgroundItem>? _param;

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex;
    if (widget.args.isApiMode) {
      _fetchApiImage();
    }
  }

  @override
  void dispose() {
    _pageFocus.dispose();
    super.dispose();
  }

  /// Never throws, even if the page has no entries.
  static const BackgroundItem _emptyItem = BackgroundItem(file: '');

  BackgroundItem _itemAt(List<BackgroundItem> items) {
    if (items.isEmpty) return _emptyItem;
    return items[_index.clamp(0, items.length - 1)];
  }

  Future<void> _fetchApiImage() async {
    setState(() => _apiLoading = true);
    var failed = false;
    try {
      final bytes = await fetchRandomImage(widget.args.apiSource!);
      if (!mounted) return;
      if (bytes == null) {
        failed = true;
      } else {
        setState(() => _apiBytes = bytes);
      }
    } catch (_) {
      failed = true;
    } finally {
      if (mounted) {
        setState(() => _apiLoading = false);
        // A refresh that fails while a picture is already on screen has no
        // status view to explain itself, so it reports through a toast.
        if (failed && _apiBytes != null) {
          ToastUtil.show(
            i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image, try again'),
          );
        }
      }
    }
  }

  /// Pulls the next page in, both on demand and a few entries ahead of the
  /// cursor so a fast 下一个 never waits on the network.
  void _prefetch(List<BackgroundItem> items, {bool force = false}) {
    final param = _param;
    if (param == null) return;
    final state = ref.read(pagingCoreProvider(param));
    if (!state.canLoadMore || state.controllerState.loading) return;
    if (!force && _index < items.length - 3) return;
    ref.read(pagingCoreProvider(param).notifier).loadNextPage();
  }

  void _next(List<BackgroundItem> items) {
    if (widget.args.isApiMode) {
      if (!_apiLoading) _fetchApiImage();
      return;
    }
    if (items.length < 2) return;

    final int next = _index + 1;
    if (next < items.length) {
      setState(() => _index = next);
      _prefetch(items);
      return;
    }

    final param = _param;
    if (param != null && ref.read(pagingCoreProvider(param)).canLoadMore) {
      _waitingForPage = true;
      _prefetch(items, force: true);
      return;
    }
    // End of the list: wrap around.
    setState(() => _index = 0);
  }

  void _prev(List<BackgroundItem> items) {
    if (widget.args.isApiMode) {
      _next(items);
      return;
    }
    if (items.length < 2) return;
    setState(() => _index = _index <= 0 ? items.length - 1 : _index - 1);
  }

  Future<void> _apply(BackgroundItem item) async {
    if (_applying) return;
    final bg = SettingsService.to.bg;
    setState(() => _applying = true);
    try {
      if (widget.args.isApiMode) {
        final bytes = _apiBytes;
        if (bytes == null) return;
        bg.setNetworkImageBytes(bytes);
      } else {
        switch (widget.args.kind!) {
          case BackgroundKind.image:
            bg.setNetworkImage(item.file);
          case BackgroundKind.video:
            bg.setNetworkVideo(item.file);
          case BackgroundKind.gradient:
            final colors = <Color>[
              for (final stop in item.gradient ?? const <BackgroundGradientStop>[])
                ColorUtil.hexToColor(stop.color),
            ];
            if (colors.length < 2) {
              ToastUtil.show(i18nOr('background_invalid_gradient', '这个渐变数据不完整'));
              return;
            }
            bg.setGradient(colors);
        }
      }
      if (mounted) ToastUtil.show(i18nOr('wallpaper_set_done', 'Background updated'));
    } catch (error) {
      if (mounted) {
        ToastUtil.show(
          i18nOr('background_apply_failed', 'Failed to apply: {msg}', args: {'msg': '$error'}),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _cycleFit() {
    final current = kWallpaperFitModes.indexOf(SettingsService.to.bgState.boxFit);
    SettingsService.to.bg.setBoxFit(kWallpaperFitModes[(current + 1) % kWallpaperFitModes.length]);
  }

  void _cycleMask() {
    final current = wallpaperMaskIndex(SettingsService.to.bgState.maskOpacity);
    SettingsService.to.bg.setMaskOpacity(kWallpaperMaskSteps[(current + 1) % kWallpaperMaskSteps.length]);
  }

  List<_PreviewAction> _buildActions() {
    final bgState = SettingsService.to.bgState;
    return <_PreviewAction>[
      if (widget.args.isApiMode)
        _PreviewAction(
          kind: _PreviewActionKind.fresh,
          icon: Icons.refresh_rounded,
          label: i18nOr('wallpaper_change_image', 'New image'),
          busy: _apiLoading,
        )
      else ...[
        _PreviewAction(
          kind: _PreviewActionKind.prev,
          icon: Icons.chevron_left_rounded,
          label: i18nOr('wallpaper_prev', 'Prev'),
        ),
        _PreviewAction(
          kind: _PreviewActionKind.next,
          icon: Icons.chevron_right_rounded,
          label: i18nOr('wallpaper_next', 'Next'),
        ),
      ],
      _PreviewAction(
        kind: _PreviewActionKind.fit,
        icon: Icons.aspect_ratio_outlined,
        label: wallpaperFitLabel(bgState.boxFit),
      ),
      _PreviewAction(
        kind: _PreviewActionKind.mask,
        icon: Icons.brightness_6_outlined,
        label: wallpaperMaskLabel(bgState.maskOpacity),
      ),
      _PreviewAction(
        kind: _PreviewActionKind.apply,
        icon: Icons.check_rounded,
        label: i18nOr('wallpaper_set_background', 'Set as background'),
        busy: _applying,
        primary: true,
      ),
    ];
  }

  void _run(_PreviewAction action, List<BackgroundItem> items) {
    switch (action.kind) {
      case _PreviewActionKind.fresh:
      case _PreviewActionKind.next:
        _next(items);
      case _PreviewActionKind.prev:
        _prev(items);
      case _PreviewActionKind.fit:
        _cycleFit();
      case _PreviewActionKind.mask:
        _cycleMask();
      case _PreviewActionKind.apply:
        _apply(_itemAt(items));
    }
  }

  void _move(int step, int count) {
    if (count == 0) return;
    setState(() => _actionIndex = (_actionIndex + step + count) % count);
  }

  KeyEventResult _onKey(KeyEvent event, List<BackgroundItem> items) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    final List<_PreviewAction> actions = _buildActions();
    if (actions.isEmpty) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowLeft) {
      _move(-1, actions.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _move(1, actions.length);
      return KeyEventResult.handled;
    }

    final bool confirm =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
    if (confirm) {
      _run(actions[_actionIndex.clamp(0, actions.length - 1)], items);
      return KeyEventResult.handled;
    }

    // Everything else — including the back key, so the route pops normally.
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(backgroundControllerProvider);
    final List<BackgroundItem> items = _resolveItems(ref);

    // A page that arrived while the user was already asking for the next entry
    // advances the cursor now.
    if (_waitingForPage && _index + 1 < items.length) {
      _waitingForPage = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index += 1);
      });
    }

    final BackgroundItem item = _itemAt(items);
    final actions = _buildActions();
    final int safeIndex = _actionIndex.clamp(0, actions.length - 1);
    final bool hasPicture = !widget.args.isApiMode || _apiBytes != null;

    return TvScaffold(
      showAppBar: false,
      child: Focus(
        focusNode: _pageFocus,
        autofocus: true,
        onKeyEvent: (node, event) => _onKey(event, items),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildViewer(bgState, item),
            if (widget.args.isApiMode && _apiLoading && hasPicture)
              const Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: AppStatusView(type: AppStatusType.loading, isMini: true),
                  ),
                ),
              ),
            _buildTopBar(items, item),
            _buildBottomBar(actions, safeIndex, items),
          ],
        ),
      ),
    );
  }

  /// The list to walk: the paged core in catalog mode, a one-entry stand-in in
  /// API mode (which downloads instead).
  List<BackgroundItem> _resolveItems(WidgetRef ref) {
    if (widget.args.isApiMode) return const <BackgroundItem>[];
    final catalog = ref.watch(backgroundCatalogProvider);
    final source = catalog.sourceById(widget.args.sourceId!);
    if (source == null) return const <BackgroundItem>[];
    final category = _pickCategory(source, widget.args.categoryId);
    if (category == null) return const <BackgroundItem>[];

    final param = wallpaperPagingParam(source, category);
    _param = param;
    final state = ref.watch(pagingCoreProvider(param));
    // Keep a page in hand well before the cursor reaches the end.
    if (state.canLoadMore && !state.controllerState.loading && _index >= state.items.length - 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefetch(state.items);
      });
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

  Widget _buildViewer(BackgroundConfigModel bgState, BackgroundItem item) {
    if (widget.args.isApiMode) {
      final bytes = _apiBytes;
      if (bytes == null) {
        // The shared status views own every loading/error surface on this page.
        return ExcludeFocus(
          child: _apiLoading
              ? const AppStatusView(type: AppStatusType.loading)
              : AppStatusView(
                  type: AppStatusType.error,
                  subtitle: i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image, try again'),
                ),
        );
      }
      return SizedBox.expand(
        child: Image.memory(bytes, fit: bgState.boxFit, gaplessPlayback: true),
      );
    }

    switch (widget.args.kind!) {
      case BackgroundKind.gradient:
        return GradientPreview(item: item);
      case BackgroundKind.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            // The live picture plays only once it is the background; here the
            // poster stands in for it.
            WallpaperNetworkImage(
              url: item.poster ?? item.file,
              fit: BoxFit.cover,
              placeholder: const ColoredBox(color: Colors.black),
              fallback: const ColoredBox(color: Colors.black),
            ),
            Center(
              child: Icon(Icons.play_circle_outline_rounded, size: 64.sp, color: Colors.white70),
            ),
          ],
        );
      case BackgroundKind.image:
        return WallpaperNetworkImage(
          url: item.file,
          fit: bgState.boxFit,
          placeholder: const ColoredBox(color: Colors.black),
          fallback: const ColoredBox(color: Colors.black),
        );
    }
  }

  Widget _buildTopBar(List<BackgroundItem> items, BackgroundItem item) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 40.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _title(item),
                  style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.args.isApiMode && items.length > 1)
                Text(
                  '${_index + 1}/${items.length}',
                  style: TextStyle(fontSize: 15.sp, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    List<_PreviewAction> actions,
    int safeIndex,
    List<BackgroundItem> items,
  ) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.sp, 40.sp, 24.sp, 20.sp),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              i18nOr('wallpaper_preview_hint', '←→ 选择按钮 · OK 确认 · 返回退出'),
              style: TextStyle(fontSize: 13.sp, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.sp),
            // Focus traversal stays out of the bar: the arrows are handled by
            // the page, and the buttons only react to the highlight computed
            // here (plus a mouse click).
            ExcludeFocus(
              child: Row(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(width: 10.sp),
                    _PreviewActionButton(
                      action: actions[i],
                      highlighted: i == safeIndex,
                      onTap: () {
                        setState(() => _actionIndex = i);
                        _run(actions[i], items);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BackgroundItem item) {
    final override = widget.args.title;
    if (override != null && override.isNotEmpty) return override;
    if (widget.args.isApiMode) {
      return '${widget.args.apiSource!.name} · ${i18nOr('wallpaper_random_image', 'Random image')}';
    }
    final name = item.name ?? '';
    return name.isNotEmpty ? name : '${i18nOr('wallpaper', 'Wallpaper')} ${_index + 1}';
  }
}

/// One bottom-bar button.
///
/// Deliberately not a `DpadFocusable`: the preview owns the keyboard and only
/// renders the highlight, so there is no traversal that can wander off.
class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({
    required this.action,
    required this.highlighted,
    required this.onTap,
  });

  final _PreviewAction action;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(22.sp);
    final bool filled = highlighted || action.primary;
    final Color fill = filled ? theme.focusColor : theme.cardColor;
    final Color foreground = filled ? theme.focusedCardColor : theme.primaryTextColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          height: 42.sp,
          padding: EdgeInsets.symmetric(horizontal: 18.sp),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(
              color: highlighted ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
              width: 2.sp,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.busy)
                SizedBox(
                  width: 24.sp,
                  height: 24.sp,
                  child: const AppStatusView(type: AppStatusType.loading, isMini: true),
                )
              else
                Icon(action.icon, size: 18.sp, color: foreground),
              SizedBox(width: 6.sp),
              Text(
                action.label,
                style: TextStyle(fontSize: 14.sp, color: foreground, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
