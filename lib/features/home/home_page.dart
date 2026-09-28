import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/features/hot/hot_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/areas/areas_page.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/features/history/history_page.dart';
import 'package:pure_live/features/music/music_page.dart';
import 'package:pure_live/features/video/video_home_page.dart';
import 'package:pure_live/features/search/tv_search_page.dart';
import 'package:pure_live/features/favorite/favorite_page.dart';
import 'package:pure_live/features/home/exit_confirm_dialog.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';
import 'package:pure_live/features/movie_playback/movie_playback_page.dart';
import 'package:pure_live/features/favorite_areas/favorite_areas_page.dart';
import 'package:pure_live/features/home/home_update_dialog.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  final bool keepAlive;

  const HomePage({super.key, this.keepAlive = true});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// One stable node for the top-left mode button, so the opening highlight
  /// can claim it when a non-live mode is active.
  final FocusNode _modeFocusNode = FocusNode();

  /// One stable node per side-menu entry, so the opening highlight can be aimed
  /// at the *selected* entry instead of whichever widget sits top-left.
  final Map<int, FocusNode> _menuFocusNodes = {};

  FocusNode _nodeFor(int index) => _menuFocusNodes.putIfAbsent(index, FocusNode.new);

  @override
  void initState() {
    super.initState();
    // Shows the update dialog once per session, after the startup check.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) HomeUpdateDialog.maybeShow(context, ref);
    });
  }

  @override
  void dispose() {
    for (final node in _menuFocusNodes.values) {
      node.dispose();
    }
    _modeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(sideMenuIndexProvider);
    final menuList = ref.watch(sideMenuListProvider);
    final mySettingsItem = ref.watch(mySettingsMenuItemProvider);
    final isExpanded = ref.watch(isMenuExpandedProvider);
    final currentTvTheme = context.tvTheme;
    // settings refresh -> home cache: on top of the widget default, the user can turn the
    // page cache off so every switch rebuilds the content fresh (and clears
    // cached tab state after nav/platform config changes).
    final bool effectiveKeepAlive =
        widget.keepAlive && ref.watch(refreshConfigControllerProvider.select((s) => s.homeKeepAlive));

    // A menu entry hidden in navigation visibility while its page is on screen leaves the
    // sidebar with no selection and the old page lingering. Auto-correct once
    // per menu-list change — to follows when it is visible (the app's landing
    // page, whatever the menu order), otherwise to the first visible entry.
    final visibleIndexes = menuList.map((item) => item.index).toSet();
    final currentIndexVisible = currentIndex == TvMenuType.settings.value || visibleIndexes.contains(currentIndex);
    if (!currentIndexVisible && visibleIndexes.isNotEmpty) {
      final landing = visibleIndexes.contains(TvMenuType.favorite.value)
          ? TvMenuType.favorite.value
          : visibleIndexes.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sideMenuIndexProvider.notifier).changeIndex(landing);
      });
    }

    // A destination can change while the remote is somewhere else entirely: the
    // empty-state actions (follows -> search, history -> hot) and the
    // auto-correction above both write the index from inside another page. The
    // keyboard then belongs to a widget that is about to be removed — the empty
    // state's button — or to an entry that just disappeared, and the d-pad layer is
    // free to settle on any tile, which is how the sidebar ended up highlighting one
    // entry while the *selected* one was another.
    //
    // Aiming the claim at the node that is now selected keeps the ring and the
    // selection telling the same story. Pressing OK on an entry already has the
    // keyboard there, so that path stays a no-op; moving the highlight around the
    // sidebar without confirming never changes the index, so browsing is untouched.
    ref.listen(sideMenuIndexProvider, (_, next) {
      if (!visibleIndexes.contains(next)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final node = _menuFocusNodes[next];
        if (node == null || node.hasFocus) return;
        DpadRegion.ofNode(node)?.noteFocus(node);
        node.requestFocus();
      });
    });

    // The rail holds labels, and every control in it is drawn at the app font
    // scale, so its width and its vertical rhythm follow the text: a fixed rail
    // cut the menu names off, and left the icons the only thing that changed
    // size when the user enlarged the font.
    final double textScale = TvTextScale.factorOf(context);
    final sidebarWidth = (isExpanded ? 200.sp : 110.sp) * textScale;

    // The top-left button switches the whole app between live / music / video.
    // Music and video own their own UI stacks; the live rail's destinations
    // below the button only render while live is active.
    final AppMode appMode = ref.watch(appModeControllerProvider);
    final bool isLiveMode = appMode == AppMode.live;

    final cacheableTypes = [
      TvMenuType.favorite,
      TvMenuType.hot,
      TvMenuType.areas,
      TvMenuType.favoriteAreas,
      TvMenuType.settings,
    ];

    final currentMenuType = TvMenuType.fromIndex(currentIndex);
    final isCurrentCacheable = cacheableTypes.contains(currentMenuType);
    final stackIndex = cacheableTypes.indexOf(currentMenuType);

    // The home page sits at the route root, so a back press here means the
    // user wants out — ask before leaving, with the donation note attached.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showExitConfirmDialog(context, ref);
      },
      // The opening highlight claims the selected entry's own node, so the app
      // opens with the remote on follows (or whatever the menu lands on) instead of
      // on the header widgets above the list.
      child: TvScaffold(
        openingFocus: isLiveMode ? _nodeFor(currentIndex) : null,
        child: Row(
          children: [
            DpadRegion(
              child: AnimatedContainer(
                // Named for the tests that pin the rail's width to the font
                // setting: the sidebar is not otherwise identifiable from outside.
                key: const Key('home-sidebar'),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: sidebarWidth,
                // Semi-transparent on purpose: the app-wide wallpaper (TvAppBackground)
                // lives below the navigator, and an opaque fill here is what hid it
                // from the menu column. The scrim keeps icons readable; the
                // background bleeds through instead of a flat card block.
                color: currentTvTheme.backgroundColor.withValues(alpha: 0.62),
                padding: EdgeInsets.symmetric(vertical: 24.sp * textScale),
                // The rail scrolls once its entries are taller than the panel: at
                // 160% ten destinations no longer fit a 1080p screen (and on a
                // 720p one they never did), and a clipped rail would hide both the
                // destinations and the way back out. `IntrinsicHeight` keeps the
                // spacers below working exactly as before while the content still
                // fits, and collapses them when it does not.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // The top-left mode button: one OK press cycles
                            // live → music → video. It sits above everything so
                            // the remote can always find its way back.
                            Padding(
                              padding: EdgeInsets.only(bottom: 14.sp * textScale),
                              child: _buildModeButton(appMode, isExpanded, textScale),
                            ),
                            // The clock sits above the backup entry, as the sidebar's
                            // header: a TV left on the home screen is a wall clock too.
                            Padding(
                              padding: EdgeInsets.only(bottom: 6.sp * textScale),
                              child: TvDigitalClock(
                                format: isExpanded ? 'HH:mm:ss' : 'HH:mm',
                                style: AppTextStyles.t20W600.copyWith(
                                  color: currentTvTheme.primaryTextColor,
                                  height: 1,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            if (isExpanded)
                              TvDigitalClock(
                                format: 'yyyy/MM/dd',
                                style: AppTextStyles.t14W500.copyWith(color: currentTvTheme.secondaryTextColor, height: 1),
                              ),
                            SizedBox(height: 15.sp * textScale),
                            Padding(
                              padding: EdgeInsets.only(bottom: 14.sp * textScale),
                              child: _buildAdaptiveItem(
                                ref: ref,
                                item: AppMenuItem(
                                  index: TvMenuType.settings.value,
                                  title: i18n('backup_manage'),
                                  shortTitle: i18n('menu_short_backup'),
                                  icon: Icons.backup_outlined,
                                ),
                                isExpanded: isExpanded,
                                isSelected: false,
                                textScale: textScale,
                                // The sidebar slot the mobile app spent on account now
                                // opens the settings page's backup directly.
                                onTap: () => const BackupRoute().push(context),
                              ),
                            ),
                            const Spacer(),
                            // The live destinations belong to live mode only;
                            // music and video draw their own content panes.
                            if (isLiveMode)
                              ...List.generate(menuList.length, (index) {
                              final item = menuList[index];
                              final isSelected = currentIndex == item.index;

                              return Padding(
                                padding: EdgeInsets.only(bottom: 14.sp * textScale),
                                child: _buildAdaptiveItem(
                                  ref: ref,
                                  item: item,
                                  isExpanded: isExpanded,
                                  isSelected: isSelected,
                                  textScale: textScale,
                                  focusNode: _nodeFor(item.index),
                                  onTap: () => ref.read(sideMenuIndexProvider.notifier).changeIndex(item.index),
                                ),
                              );
                            }),
                            const Spacer(),
                            Padding(
                              padding: EdgeInsets.only(bottom: 14.sp * textScale),
                              child: TvIconButton(
                                icon: AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  child: const Icon(Icons.arrow_forward_ios_rounded),
                                ),
                                // Expanded already spells every entry out; collapsed is
                                // the state where the arrow needs a name.
                                label: isExpanded ? null : i18n('menu_short_expand'),
                                size: TvIconButtonSize.medium,
                                isSecondary: true,
                                onTap: () => ref.read(isMenuExpandedProvider.notifier).toggle(),
                              ),
                            ),
                            _buildAdaptiveItem(
                              ref: ref,
                              item: mySettingsItem,
                              isExpanded: isExpanded,
                              isSelected: currentIndex == mySettingsItem.index,
                              textScale: textScale,
                              focusNode: _nodeFor(mySettingsItem.index),
                              // Settings opens as its own page (title bar, back button
                              // and the configuration-preview action), like the desktop
                              // app, instead of swapping the content pane.
                              onTap: () => const SettingsMenuRoute().push(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: DpadRegion(
                child: Padding(
                  padding: EdgeInsets.all(8.sp),
                  // Music and video own the whole pane; only live mode runs the
                  // keep-alive home stack below.
                  child: !isLiveMode
                      ? Container(
                          key: ValueKey('mode_${appMode.name}'),
                          child: _buildModeContent(appMode)
                              .animate()
                              .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                                duration: 250.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        )
                      : effectiveKeepAlive
                      ? Stack(
                          children: [
                            Visibility(
                              visible: isCurrentCacheable,
                              maintainState: true,
                              child: IndexedStack(
                                index: stackIndex != -1 ? stackIndex : 0,
                                children: cacheableTypes.map((type) {
                                  final isCurrent = currentMenuType == type;
                                  return TvLazyWrapper(
                                    isCurrent: isCurrent,
                                    child: _buildPageContent(context, ref, type)
                                        .animate(target: isCurrent ? 1.0 : 0.0)
                                        .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                                        .scale(
                                          begin: const Offset(0.95, 0.95),
                                          end: const Offset(1.0, 1.0),
                                          duration: 250.ms,
                                          curve: Curves.easeOutCubic,
                                        ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (!isCurrentCacheable)
                              Container(
                                key: ValueKey(currentIndex),
                                child: _buildPageContent(context, ref, currentMenuType)
                                    .animate()
                                    .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                                    .scale(
                                      begin: const Offset(0.95, 0.95),
                                      end: const Offset(1.0, 1.0),
                                      duration: 250.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                              ),
                          ],
                        )
                      : Container(
                          key: ValueKey(currentIndex),
                          child: _buildPageContent(context, ref, currentMenuType)
                              .animate()
                              .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                                duration: 250.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The top-left button: shows the active mode, one OK press cycles to the
  /// next. Deliberately not an [AppMenuItem] — it carries no menu index.
  Widget _buildModeButton(AppMode mode, bool isExpanded, double textScale) {
    final (String label, String short, IconData icon) = switch (mode) {
      AppMode.live => (i18n('mode_live'), i18n('menu_short_mode_live'), Icons.live_tv_rounded),
      AppMode.music => (i18n('mode_music'), i18n('menu_short_mode_music'), Icons.library_music_outlined),
      AppMode.video => (i18n('mode_video'), i18n('menu_short_mode_video'), Icons.movie_outlined),
    };

    if (isExpanded) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.sp * textScale),
        child: TvButton(
          title: label,
          icon: Icon(icon, size: 32.sp * textScale),
          iconPosition: TvIconPosition.left,
          size: TvButtonSize.mini,
          focusNode: _modeFocusNode,
          onTap: () => ref.read(appModeControllerProvider.notifier).cycle(),
        ),
      );
    }

    return TvIconButton(
      icon: Icon(icon),
      label: short,
      size: TvIconButtonSize.medium,
      focusNode: _modeFocusNode,
      onTap: () => ref.read(appModeControllerProvider.notifier).cycle(),
    );
  }

  /// The full content pane for the non-live modes.
  Widget _buildModeContent(AppMode mode) => switch (mode) {
    AppMode.live => const SizedBox.shrink(), // handled by the live stack
    AppMode.music => const MusicPage(),
    AppMode.video => const VideoHomePage(),
  };

  Widget _buildAdaptiveItem({
    required WidgetRef ref,
    required AppMenuItem item,
    required bool isExpanded,
    required bool isSelected,
    required VoidCallback onTap,
    required double textScale,
    FocusNode? focusNode,
  }) {
    if (isExpanded) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.sp * textScale),
        child: TvButton(
          title: item.title,
          icon: Icon(item.icon, size: 32.sp * textScale),
          iconPosition: TvIconPosition.left,
          size: TvButtonSize.mini,
          isSecondary: !isSelected,
          selected: isSelected,
          useFadedFocus: true,
          focusNode: focusNode,
          onTap: onTap,
        ),
      ).animate().fadeIn(duration: 150.ms).slideX(begin: -0.05, end: 0, duration: 200.ms, curve: Curves.easeOutCubic);
    }

    return TvIconButton(
      icon: Icon(item.icon),
      // Collapsed rail: the icon alone left the destinations ambiguous, so each
      // tile carries its two-character name underneath.
      label: item.shortTitle.isEmpty ? item.title : item.shortTitle,
      selected: isSelected,
      size: TvIconButtonSize.medium,
      useFadedFocus: true,
      isSecondary: !isSelected,
      focusNode: focusNode,
      onTap: onTap,
    );
  }

  Widget _buildPageContent(BuildContext context, WidgetRef ref, TvMenuType type) {
    switch (type) {
      case TvMenuType.settings:
        return const SettingsCatalogView();
      case TvMenuType.favorite:
        return const FavoritePage();
      case TvMenuType.hot:
        return const HotPage();
      case TvMenuType.areas:
        return const AreasPage();
      case TvMenuType.favoriteAreas:
        return const FavoriteAreasPage();
      case TvMenuType.moviePlayback:
        return const MoviePlaybackPage();
      case TvMenuType.search:
        return const TvSearchPage();
      case TvMenuType.history:
        return const HistoryPage();
    }
  }
}
