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

  /// Pressing the tab that is already current: reload what it shows.
  ///
  /// The returned future drives the bar's progress line — it stays up until the
  /// work actually finished, so an instant local reload, a slow fetch and a
  /// failure all read correctly.
  final Future<void> Function(int index)? onTabRefresh;

  /// Whether the data behind this bar is being (re)loaded right now.
  ///
  /// Not every refresh is one this bar started: the favourites page runs an
  /// auto-refresh timer and an import verification pass, a paged grid retries
  /// from its empty state, and a platform catalogue reload can be asked for from
  /// the bar above. Pages hand in the state their grid is fed from, so all of
  /// those show on the same line.
  final bool refreshing;

  /// Whether this bar draws the refresh line at all.
  ///
  /// A page with two stacked bars keeps one line: the bar that sits above the
  /// list carries the state, and the other one turns this off so a press of its
  /// own does not light a second line — the refresh it starts still shows, on
  /// the bar next to the list.
  final bool showRefreshLine;

  final List<DpadEffect>? effects;

  /// Switch the tab as soon as focus lands on it, not only on OK.
  ///
  /// Modal dialogs (the room switcher) want this: there the highlight and the
  /// shown content must never disagree, and a focus move *is* the intent. Page
  /// tab bars keep the default (false) so merely walking across tabs does not
  /// reload their content.
  final bool switchOnFocus;

  /// Focus node for the first tab.
  ///
  /// A dialog that opens on the bar hands this in as its initial focus, so the
  /// keyboard lands on a tab rather than on whatever the focus guard finds
  /// first (which for a tabbed dialog body is the close button at the bottom).
  final FocusNode? firstTabFocusNode;

  /// Focus-driven tab switch ([switchOnFocus]), customised: when set, a focus
  /// move calls this instead of [onTabChange], so the caller can switch the
  /// content while the keyboard stays on the tab bar (left/right keeps walking
  /// tabs; down enters the list).
  final void Function(int index)? onTabFocused;

  const TvTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChange,
    this.effects,
    this.onTabRefresh,
    this.refreshing = false,
    this.showRefreshLine = true,
    this.switchOnFocus = false,
    this.onTabFocused,
    this.firstTabFocusNode,
  });

  @override
  State<TvTabBar> createState() => _TvTabBarState();
}

class _TvTabBarState extends State<TvTabBar> {
  /// Keys the individual tabs so the currently selected one can be revealed.
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  /// Whether this bar's own refresh is running — see [_handleRefresh].
  bool _refreshing = false;

  /// Least time the line stays up for a refresh this bar started.
  ///
  /// The local reloads (a re-slice of data already in memory, like the areas
  /// sub-category bar) come back within a microtask, and a line that appears and
  /// vanishes inside one frame reads as a glitch instead of as the feedback the
  /// second press was asking for. Network refreshes outlast it on their own.
  static const Duration _minRefreshVisible = Duration(milliseconds: 450);

  /// Runs a refresh this bar started, with the progress line up meanwhile.
  Future<void> _handleRefresh(int index) async {
    final refresh = widget.onTabRefresh;
    if (refresh == null || _refreshing) return;

    // The bar owns this state on purpose: a page-level flag would rebuild the
    // page, and the paged views key their controller by the `PagingParam` they
    // build, so a rebuild mid-refresh traded the grid's scroll position for a
    // progress line.
    setState(() => _refreshing = true);
    try {
      await Future.wait<void>([refresh(index), Future<void>.delayed(_minRefreshVisible)]);
    } catch (_) {
      // A refresh reports failures where its data lives (a paging core keeps the
      // error, the areas bridge its own view); swallowing here only keeps a
      // thrown task from leaving the line up.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

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
    // TvButton.medium's geometry (64.w pill, t26 label, 24.w icon), the same
    // size the sidebar's menu buttons use.
    final double height = 64.0.w;
    final borderRadius = BorderRadius.circular(height / 2);

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: Stack(
        // The progress line is painted into the gap the pages keep under the bar
        // (12-20 design px), so it never pushes the grid down while it shows.
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: height,
            alignment: Alignment.center,
            color: Colors.transparent,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              // The viewport must clip: Clip.none paints the whole bar outside a
              // narrow container. The content padding keeps the first/last tab
              // inside the scroll bounds so the focus scale is not sheared.
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
                      // TvButton.medium runs 1.06; the bar matches it.
                      ...TvFocusStyle.effects(currentTvTheme, borderRadius, scale: 1.06, glow: false),
                      DpadCustomEffect((context, state, child) {
                        final isFocused = state.focused;

                        // TvButton's states exactly: selected and focused fill
                        // solid accent, idle keeps a translucent buttonSurface
                        // pill, and the label is white t26W500 in every state.
                        final Color bgColor;
                        if (isSelected || isFocused) {
                          bgColor = currentTvTheme.focusColor;
                        } else {
                          bgColor = currentTvTheme.buttonSurface.withValues(
                            alpha: currentTvTheme.isLight ? 0.85 : 0.75,
                          );
                        }
                        const Color foregroundColor = Colors.white;
                        final TextStyle baseStyle = AppTextStyles.t26W500;

                        return AnimatedContainer(
                          duration: TvFocusStyle.focusDuration(isFocused),
                          curve: TvFocusStyle.curve,
                          height: height,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 28.w),
                          decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
                          child: IconTheme(
                            data: IconThemeData(color: foregroundColor),
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
                    focusNode: index == 0 ? widget.firstTabFocusNode : null,
                    onFocusChange: (focused) {
                      if (!focused || !widget.switchOnFocus || index == widget.currentIndex) return;
                      (widget.onTabFocused ?? widget.onTabChange)(index);
                    },
                    onSelect: () {
                      if (index == widget.currentIndex) {
                        _handleRefresh(index);
                      } else {
                        widget.onTabChange(index);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Fixed 24x24 icon slot (TvButton.medium's size): platform
                        // logos differ in size and must align with the label.
                        if (tab.icon != null) ...[
                          SizedBox(width: 24.w, height: 24.w, child: Center(child: tab.icon)),
                          SizedBox(width: 10.w),
                        ],
                        // Never wrap: ellipsize instead, so the pill stays one line.
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
          // Sits below the pills, in the gap the page leaves under this bar; the
          // bar's own height is unchanged, so nothing below it moves.
          if (widget.showRefreshLine && (widget.refreshing || _refreshing))
            Positioned(left: 16.sp, right: 16.sp, bottom: -8.sp, child: const _TabRefreshLine()),
        ],
      ),
    );
  }
}

/// The line a tab bar shows while a refresh it started is running.
class _TabRefreshLine extends StatelessWidget {
  const _TabRefreshLine();

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    return LinearProgressIndicator(
      minHeight: 4.sp,
      borderRadius: BorderRadius.circular(2.sp),
      color: currentTvTheme.focusColor,
      // A faint track the moving segment reads against, instead of the line
      // appearing out of nowhere.
      backgroundColor: currentTvTheme.focusColor.withValues(alpha: currentTvTheme.isLight ? 0.16 : 0.22),
    );
  }
}
