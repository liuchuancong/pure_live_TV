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
import 'package:pure_live/features/search/tv_search_page.dart';
import 'package:pure_live/features/favorite/favorite_page.dart';
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
  /// One stable node per side-menu entry, so the opening highlight can be aimed
  /// at the *selected* entry instead of whichever widget sits top-left.
  final Map<int, FocusNode> _menuFocusNodes = {};

  FocusNode _nodeFor(int index) => _menuFocusNodes.putIfAbsent(index, FocusNode.new);

  @override
  void dispose() {
    for (final node in _menuFocusNodes.values) {
      node.dispose();
    }
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
    final bool effectiveKeepAlive = widget.keepAlive && ref.watch(refreshConfigControllerProvider).homeKeepAlive;

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

    final sidebarWidth = isExpanded ? 200.sp : 110.sp;

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
        openingFocus: _nodeFor(currentIndex),
        child: Row(
          children: [
            DpadRegion(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: sidebarWidth,
                // Semi-transparent on purpose: the app-wide wallpaper (TvAppBackground)
                // lives below the navigator, and an opaque fill here is what hid it
                // from the menu column. The scrim keeps icons readable; the
                // background bleeds through instead of a flat card block.
                color: currentTvTheme.backgroundColor.withValues(alpha: 0.62),
                padding: EdgeInsets.symmetric(vertical: 24.sp),
                child: Column(
                  children: [
                    // The clock sits above the backup entry, as the sidebar's
                    // header: a TV left on the home screen is a wall clock too.
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.sp),
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
                    SizedBox(height: 15.sp),
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.sp),
                      child: _buildAdaptiveItem(
                        ref: ref,
                        item: AppMenuItem(
                          index: TvMenuType.settings.value,
                          title: i18n('backup_manage'),
                          icon: Icons.backup_outlined,
                        ),
                        isExpanded: isExpanded,
                        isSelected: false,
                        // The sidebar slot the mobile app spent on account now
                        // opens the settings page's backup directly.
                        onTap: () => const BackupRoute().push(context),
                      ),
                    ),
                    const Spacer(),
                    ...List.generate(menuList.length, (index) {
                      final item = menuList[index];
                      final isSelected = currentIndex == item.index;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 14.sp),
                        child: _buildAdaptiveItem(
                          ref: ref,
                          item: item,
                          isExpanded: isExpanded,
                          isSelected: isSelected,
                          focusNode: _nodeFor(item.index),
                          onTap: () => ref.read(sideMenuIndexProvider.notifier).changeIndex(item.index),
                        ),
                      );
                    }),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.sp),
                      child: TvIconButton(
                        icon: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: const Icon(Icons.arrow_forward_ios_rounded),
                        ),
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
            Expanded(
              child: DpadRegion(
                child: Padding(
                  padding: EdgeInsets.all(8.sp),
                  child: effectiveKeepAlive
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

  Widget _buildAdaptiveItem({
    required WidgetRef ref,
    required AppMenuItem item,
    required bool isExpanded,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    if (isExpanded) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        child: TvButton(
          title: item.title,
          icon: Icon(item.icon, size: 32.sp),
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
