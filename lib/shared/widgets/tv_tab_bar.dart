import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvTabItemData {
  final String title;
  final Widget? icon;

  /// Stable identity of the tab.
  ///
  /// The bar keys its children with this value so a rebuild (or a platform
  /// list that changed length) can never recycle an element onto a different
  /// tab and leave focus sitting on the wrong one. Defaults to [title] when a
  /// caller does not supply one.
  final String? id;

  const TvTabItemData({required this.title, this.icon, this.id});

  /// Identity used for element keys.
  String get tabId => id ?? title;

  /// Platform tab: the platform logo when the asset exists, otherwise a
  /// neutral icon.
  ///
  /// The synthetic "all" platform has no logo file, and a platform can be
  /// added before its artwork lands; without the fallback the tab renders an
  /// empty gap (and the asset error is logged) instead of an icon.
  factory TvTabItemData.site(Site site) {
    if (site.id == Sites.allSite) {
      return TvTabItemData(
        id: site.id,
        title: site.name,
        icon: Icon(Icons.apps_rounded, size: 24.sp),
      );
    }
    return TvTabItemData(
      id: site.id,
      title: site.name,
      icon: Image.asset(
        site.logo,
        width: 24.sp,
        height: 24.sp,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.live_tv_rounded, size: 24.sp),
      ),
    );
  }
}

class TvTabBar extends StatefulWidget {
  final List<TvTabItemData> tabs;
  final int currentIndex;
  final void Function(int index) onTabChange;
  final void Function(int index)? onTabRefresh;
  final List<DpadEffect>? effects;

  const TvTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChange,
    this.effects,
    this.onTabRefresh,
  });

  @override
  State<TvTabBar> createState() => _TvTabBarState();
}

class _TvTabBarState extends State<TvTabBar> {
  /// Keys the individual tabs so the currently selected one can be revealed.
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(TvTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A tab can become current without ever being focused (pointer input,
    // a programmatic switch, or a focus move that left the bar). The d-pad
    // layer only reveals tabs it focused, so the bar would keep its previous
    // offset and leave the new current tab clipped at the edge — visibly
    // "the first tab does not come back" until another tab is picked.
    if (oldWidget.currentIndex != widget.currentIndex) {
      _revealCurrentTab();
    }
  }

  void _revealCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.currentIndex < 0 || widget.currentIndex >= widget.tabs.length) return;

      final BuildContext? tabContext =
          _tabKeys[_keyId(widget.currentIndex, widget.tabs[widget.currentIndex])]?.currentContext;
      if (tabContext == null) return;

      Scrollable.ensureVisible(
        tabContext,
        // Match the dpad layer's snap scrolling (see app.dart): an animated
        // reveal here races with dpad's own focus-driven scroll and the two
        // cancel each other out, leaving the current tab clipped.
        duration: Duration.zero,
      );
    });
  }

  /// Global keys must stay unique even when two tabs share a title (duplicate
  /// category names are possible), so the position is part of the identity.
  String _keyId(int index, TvTabItemData tab) => '$index:${tab.tabId}';

  GlobalKey _keyFor(int index, TvTabItemData tab) => _tabKeys.putIfAbsent(_keyId(index, tab), () => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final double height = 44.sp;
    final borderRadius = BorderRadius.circular(height / 2);

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: Container(
        width: double.infinity,
        height: 50.sp,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          // Content padding instead of container padding: it scrolls with
          // the items, so at min/max scroll extent the first/last tab keeps
          // a margin inside the viewport and the focus scale (1.05) is not
          // clipped by the viewport edge.
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          itemCount: widget.tabs.length,
          itemBuilder: (context, index) {
            final tab = widget.tabs[index];
            final isSelected = widget.currentIndex == index;

            final dynamicEffects =
                widget.effects ??
                [
                  DpadScaleEffect(
                    scale: 1.05,
                    pressedScale: 0.98,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                  ),
                  DpadCustomEffect((context, state, child) {
                    final isFocused = state.focused;

                    final bgColor = isSelected
                        ? currentTvTheme.focusColor
                        : isFocused
                        ? currentTvTheme.focusColor.withValues(alpha: 0.5)
                        : Colors.transparent;

                    final foregroundColor = isSelected
                        ? currentTvTheme.onFadedFocusColor
                        : isFocused
                        ? currentTvTheme.onFadedFocusColor
                        : currentTvTheme.primaryTextColor;

                    final baseStyle = isSelected || isFocused ? AppTextStyles.t20W600 : AppTextStyles.t20;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      height: height,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 28.sp),
                      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
                      child: IconTheme(
                        data: IconThemeData(size: 26.sp, color: foregroundColor),
                        child: DefaultTextStyle(
                          style: baseStyle.copyWith(color: foregroundColor),
                          child: child,
                        ),
                      ),
                    );
                  }),
                ];

            return Padding(
              key: _keyFor(index, tab),
              padding: EdgeInsets.symmetric(horizontal: 6.sp),
              child: DpadFocusable(
                effects: dynamicEffects,
                onSelect: () {
                  if (index == widget.currentIndex) {
                    widget.onTabRefresh?.call(index);
                  } else {
                    widget.onTabChange(index);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tab.icon != null) ...[tab.icon!, SizedBox(width: 10.sp)],
                    Center(child: Text(tab.title)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
