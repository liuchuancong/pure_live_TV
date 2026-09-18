import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_focus_style.dart';
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
        icon: Icon(Icons.apps_rounded, size: 26.sp),
      );
    }
    return TvTabItemData(
      id: site.id,
      title: site.name,
      icon: Image.asset(
        site.logo,
        width: 26.sp,
        height: 26.sp,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.live_tv_rounded, size: 26.sp),
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
    final double height = 56.sp;
    final borderRadius = BorderRadius.circular(height / 2);

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: Container(
        width: double.infinity,
        height: 64.sp,
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
                  // The shared focus language (scale + ring + halo); the fill
                  // itself is the custom effect below, because a tab tints
                  // instead of filling solid.
                  ...TvFocusStyle.effects(currentTvTheme, borderRadius),
                  DpadCustomEffect((context, state, child) {
                    final isFocused = state.focused;

                    // 三态各有可辨识的容器：选中=实心主题色，焦点=半透明主题色，
                    // 未选中=低透明度底色胶囊（不再是裸图标文字）。
                    final bgColor = isSelected
                        ? currentTvTheme.focusColor
                        : isFocused
                        ? currentTvTheme.focusColor.withValues(alpha: 0.45)
                        : currentTvTheme.primaryTextColor.withValues(alpha: 0.10);

                    // House style: tab icons and focused/selected text are
                    // always white, in every theme mode — the accent fills are
                    // strong enough to carry white in both.
                    final foregroundColor = isSelected || isFocused ? Colors.white : currentTvTheme.primaryTextColor;

                    final baseStyle = isSelected || isFocused ? AppTextStyles.t24W600 : AppTextStyles.t24;

                    return AnimatedContainer(
                      duration: TvFocusStyle.duration,
                      curve: TvFocusStyle.curve,
                      height: height,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 32.sp),
                      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
                      // Icons render white in every state. `Icon` widgets pick
                      // this up through IconTheme; image logos keep their own
                      // artwork (a srcIn colour filter made them disappear).
                      child: IconTheme(
                        data: const IconThemeData(color: Colors.white),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 固定尺寸的图标位：各平台 logo 实际大小不一，统一收进
                    // 24x36 的居中槽位，保证与文字基线对齐。
                    if (tab.icon != null) ...[
                      SizedBox(width: 28.sp, height: 28.sp, child: Center(child: tab.icon)),
                      SizedBox(width: 12.sp),
                    ],
                    // 中文标题不允许换行：超宽时省略，胶囊保持单行
                    Center(
                      child: Text(
                        tab.title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
