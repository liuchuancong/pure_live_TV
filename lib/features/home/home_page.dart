import 'package:dpad/dpad.dart';
import 'package:pure_live/modules/media/index.dart';
import 'package:pure_live/features/hot/hot_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/modules/music/music_page.dart';
import 'package:pure_live/features/areas/areas_page.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/features/history/history_page.dart';
import 'package:pure_live/modules/video/video_home_page.dart';
import 'package:pure_live/features/search/tv_search_page.dart';
import 'package:pure_live/features/favorite/favorite_page.dart';
import 'package:pure_live/features/home/home_update_dialog.dart';
import 'package:pure_live/features/home/exit_confirm_dialog.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';
import 'package:pure_live/features/movie_playback/movie_playback_page.dart';
import 'package:pure_live/features/favorite_areas/favorite_areas_page.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  final bool keepAlive;

  const HomePage({super.key, this.keepAlive = true});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// One stable node for the mode switch button, so the opening highlight can
  /// claim it when a non-live mode is active.
  final FocusNode _modeFocusNode = FocusNode();

  /// One stable node per side-menu entry, so the opening highlight can be aimed
  /// at the *selected* entry instead of whichever widget sits top-left.
  final Map<int, FocusNode> _menuFocusNodes = {};

  /// One stable node per music/video section entry.
  final Map<String, FocusNode> _sectionFocusNodes = {};

  FocusNode _sectionNode(String key) => _sectionFocusNodes.putIfAbsent(key, FocusNode.new);

  /// The mode switch button (in the old backup slot): shows the active mode,
  /// one OK press cycles 直播 → 视频 → 音乐.
  Widget _buildModeButton(AppMode mode, bool isExpanded, double textScale) {
    final (String label, String short, IconData icon) = switch (mode) {
      AppMode.live => (i18n('mode_live'), i18n('menu_short_mode_live'), Icons.live_tv_rounded),
      AppMode.video => (i18n('mode_video'), i18n('menu_short_mode_video'), Icons.movie_outlined),
      AppMode.music => (i18n('mode_music'), i18n('menu_short_mode_music'), Icons.library_music_outlined),
    };

    // A control, not a state: the mode's name on the button already says
    // what is active, so it renders like every other rail entry and lights
    // up only under focus (it used to sit in the selected fill forever,
    // competing with the genuinely selected section below it).
    return _buildAdaptiveItem(
      ref: ref,
      item: AppMenuItem(index: -1, title: label, shortTitle: short, icon: icon),
      isExpanded: isExpanded,
      isSelected: false,
      textScale: textScale,
      focusNode: _modeFocusNode,
      onTap: _showModeDialog,
    );
  }

  /// The mode picker dialog (bmsc's login-placeholder spirit: an explicit
  /// choice, not a blind cycle). Picking a different mode first closes
  /// whatever the previous module was playing — the speakers pass cleanly.
  Future<void> _showModeDialog() async {
    final current = ref.read(appModeControllerProvider);
    final selected = await showDialog<AppMode>(
      context: context,
      builder: (context) {
        final tvTheme = context.tvTheme;
        final accent = tvTheme.focusColor;
        return Dialog(
          backgroundColor: tvTheme.cardColor,
          // Compact on purpose: a mode picker is three rows, not a page.
          insetPadding: EdgeInsets.symmetric(horizontal: 480.sp, vertical: 240.sp),
          child: Padding(
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  i18n('mode_picker_title'),
                  style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.sp),
                for (final (mode, icon) in [
                  (AppMode.live, Icons.live_tv_rounded),
                  (AppMode.video, Icons.movie_outlined),
                  (AppMode.music, Icons.library_music_outlined),
                ])
                  Padding(
                    padding: EdgeInsets.only(top: 10.sp),
                    child: TvFocusable(
                      autofocus: mode == current,
                      onTap: () => Navigator.pop(context, mode),
                      builder: (context, focused, child) {
                        final isSelected = mode == current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: 72.sp,
                          padding: EdgeInsets.symmetric(horizontal: 20.sp),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.18)
                                : focused
                                ? accent.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14.sp),
                            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, size: 30.sp, color: isSelected ? accent : tvTheme.secondaryTextColor),
                              SizedBox(width: 14.sp),
                              Expanded(
                                child: Text(
                                  i18n(switch (mode) {
                                    AppMode.live => 'mode_live',
                                    AppMode.video => 'mode_video',
                                    AppMode.music => 'mode_music',
                                  }),
                                  style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, 
                                    color: isSelected ? accent : tvTheme.primaryTextColor,
                                  ),
                                ),
                              ),
                              if (isSelected) Icon(Icons.check_rounded, size: 26.sp, color: accent),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    // Switching modules closes the previous one's playback entirely: music
    // stops (queue dropped), live rooms were never playing on this screen.
    await ref.read(musicPlayerControllerProvider.notifier).stop();
    ref.read(appModeControllerProvider.notifier).setMode(selected);
  }

  /// The active mode's own rail entries. Live reuses the configured side menu;
  /// music and video carry their fixed section lists, selected through their
  /// section-index providers.
  List<Widget> _buildModeRailItems(AppMode mode, bool isExpanded, double textScale) {
    switch (mode) {
      case AppMode.live:
        final menuList = ref.watch(sideMenuListProvider);
        final currentIndex = ref.watch(sideMenuIndexProvider);
        return [
          for (final item in menuList)
            Padding(
              padding: EdgeInsets.only(bottom: 20.sp * textScale),
              child: _buildAdaptiveItem(
                ref: ref,
                item: item,
                isExpanded: isExpanded,
                isSelected: currentIndex == item.index,
                textScale: textScale,
                focusNode: _nodeFor(item.index),
                onTap: () => ref.read(sideMenuIndexProvider.notifier).changeIndex(item.index),
              ),
            ),
        ];
      case AppMode.music:
        // Four rail destinations over the top-tab groups (see kMusicRailGroups):
        // 搜索, then 歌单 on its own, then the discovery and library groups —
        // the tabbed sections live behind the content pane's tab bar.
        const labels = <(String, IconData)>[
          ('music_tab_search', Icons.search_rounded),
          ('music_playlists', Icons.playlist_add_check_rounded),
          ('music_discover', Icons.explore_outlined),
          ('music_mine', Icons.person_outline_rounded),
        ];
        final selected = ref.watch(musicSectionIndexProvider);
        final railIndex = musicRailIndexFor(MusicSection.values[selected.clamp(0, MusicSection.values.length - 1)]);
        return [
          for (final (index2, (labelKey, icon)) in labels.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: 20.sp * textScale),
              child: _buildAdaptiveItem(
                ref: ref,
                item: AppMenuItem(index: index2, title: i18n(labelKey), shortTitle: i18n(labelKey), icon: icon),
                isExpanded: isExpanded,
                isSelected: railIndex == index2,
                textScale: textScale,
                focusNode: _sectionNode('music_$index2'),
                onTap: () => ref.read(musicSectionIndexProvider.notifier).change(kMusicRailGroups[index2].first.index),
              ),
            ),
        ];
      case AppMode.video:
        // newBV's left rail, its exact item order: 搜索/个人/主页/分区/影视 —
        // each entry maps to its VideoSection index.
        const entries = <(int, String, IconData)>[
          (3, 'video_tab_search', Icons.search_rounded),
          (4, 'video_personal', Icons.person_outline_rounded),
          (0, 'video_tab_home', Icons.home_outlined),
          (1, 'video_tab_region', Icons.category_outlined),
          (2, 'video_tab_pgc', Icons.movie_outlined),
        ];
        final selected = ref.watch(videoSectionIndexProvider);
        return [
          for (final (railIndex, (sectionIndex, labelKey, icon)) in entries.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: 20.sp * textScale),
              child: _buildAdaptiveItem(
                ref: ref,
                item: AppMenuItem(index: railIndex, title: i18n(labelKey), shortTitle: i18n(labelKey), icon: icon),
                isExpanded: isExpanded,
                isSelected: selected == sectionIndex,
                textScale: textScale,
                focusNode: _sectionNode('video_$railIndex'),
                onTap: () => ref.read(videoSectionIndexProvider.notifier).change(sectionIndex),
              ),
            ),
        ];
    }
  }

  /// The full content pane for the non-live modes: login gate first (the bmsc
  /// pattern — a lock placeholder that opens the QR login page), then the
  /// selected section, with music pinning its resident mini player bar.
  Widget _buildModePane(AppMode mode) {
    if (mode == AppMode.music) {
      // Once per run — the controller guards repeats: the resume option
      // restores the last queue the first time the music pane shows.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(musicPlayerControllerProvider.notifier).maybeResumeLastSession();
      });
      final sectionIndex = ref.watch(musicSectionIndexProvider);
      return BilibiliLoginGate(
        child: Column(
          children: [
            Expanded(
              child: MusicSectionView(
                section: MusicSection.values[sectionIndex.clamp(0, MusicSection.values.length - 1)],
              ),
            ),
            const MusicMiniBar(),
          ],
        ),
      );
    }
    final sectionIndex = ref.watch(videoSectionIndexProvider);
    return BilibiliLoginGate(
      child: VideoSectionView(section: VideoSection.values[sectionIndex.clamp(0, VideoSection.values.length - 1)]),
    );
  }

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
    for (final node in _sectionFocusNodes.values) {
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
    // Expanded carries the small pill (icon + four-character name) with margin;
    // collapsed keeps the 64dp icon tile.
    final sidebarWidth = (isExpanded ? 216.sp : 110.sp) * textScale;

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
                  builder: (context, constraints) => Column(
                    children: [
                      // Header stays pinned: the clock is a wall clock, and the
                      // mode switch must be reachable no matter how far the
                      // section list has scrolled.
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.sp * textScale),
                        child: TvDigitalClock(
                          format: isExpanded ? 'HH:mm:ss' : 'HH:mm',
                          style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, 
                            color: currentTvTheme.primaryTextColor,
                            height: 1,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (isExpanded)
                        TvDigitalClock(
                          format: 'yyyy/MM/dd',
                          style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: currentTvTheme.secondaryTextColor, height: 1),
                        ),
                      SizedBox(height: 15.sp * textScale),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.sp * textScale),
                        child: _buildModeButton(appMode, isExpanded, textScale),
                      ),
                      // The active mode's own navigation — live destinations,
                      // music sections or video sections — is the only part
                      // that scrolls: video carries eight entries and overflow
                      // must not push the footer controls off screen.
                      Expanded(
                        // Edge fades mark the clipped entries as scroll
                        // content: at the largest font scale a half-shown
                        // item otherwise reads as a broken rail.
                        child: SingleChildScrollView(
                          child: Column(children: _buildModeRailItems(appMode, isExpanded, textScale)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.sp * textScale),
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
            Expanded(
              child: DpadRegion(
                child: Padding(
                  padding: EdgeInsets.all(8.sp),
                  // Music and video own the whole pane (their own rail above,
                  // login-gated content below); only live mode runs the
                  // keep-alive home stack.
                  child: !isLiveMode
                      ? Container(
                          key: ValueKey('mode_${appMode.name}'),
                          child: _buildModePane(appMode)
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
          icon: Icon(item.icon, size: 36.sp * textScale),
          iconPosition: TvIconPosition.left,
          size: TvButtonSize.small,
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
