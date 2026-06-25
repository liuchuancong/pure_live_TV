import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/modules/hot/hot_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pure_live/widgets/tv_icon_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/theme/styles/app_styles.dart';
import 'package:pure_live/modules/areas/areas_page.dart';
import 'package:pure_live/modules/home/home_provider.dart';
import 'package:pure_live/modules/history/history_page.dart';
import 'package:pure_live/modules/search/tv_search_page.dart';
import 'package:pure_live/modules/favorite/favorite_page.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/favorite_areas/favorite_areas_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(sideMenuIndexProvider);
    final menuList = ref.watch(sideMenuListProvider);
    final myProfileItem = ref.watch(myProfileMenuItemProvider);
    final mySettingsItem = ref.watch(mySettingsMenuItemProvider);
    final isExpanded = ref.watch(isMenuExpandedProvider);
    final currentTvTheme = context.tvTheme;

    final sidebarWidth = isExpanded ? 250.sp : 110.sp;

    return TvScaffold(
      child: Container(
        color: currentTvTheme.backgroundColor,
        child: Row(
          children: [
            DpadRegion(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: sidebarWidth,
                color: currentTvTheme.cardColor,
                padding: EdgeInsets.symmetric(vertical: 24.sp),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.sp),
                      child: _buildAdaptiveItem(
                        ref: ref,
                        item: myProfileItem,
                        isExpanded: isExpanded,
                        isSelected: currentIndex == myProfileItem.index,
                        onTap: () => ref.read(sideMenuIndexProvider.notifier).state = myProfileItem.index,
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
                          onTap: () => ref.read(sideMenuIndexProvider.notifier).state = item.index,
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
                        onTap: () {
                          ref.read(isMenuExpandedProvider.notifier).update((state) => !state);
                        },
                      ),
                    ),
                    _buildAdaptiveItem(
                      ref: ref,
                      item: mySettingsItem,
                      isExpanded: isExpanded,
                      isSelected: currentIndex == mySettingsItem.index,
                      onTap: () => ref.read(sideMenuIndexProvider.notifier).state = mySettingsItem.index,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: DpadRegion(
                child: Padding(padding: EdgeInsets.all(8.sp), child: _buildContentByIndex(context, ref, currentIndex)),
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
  }) {
    if (isExpanded) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        child: TvButton(
          title: item.title,
          icon: Icon(item.icon, size: 32.sp),
          iconPosition: TvIconPosition.left,
          size: TvButtonSize.medium,
          isSecondary: !isSelected,
          onTap: onTap,
        ),
      ).animate().fadeIn(duration: 150.ms).slideX(begin: -0.1, end: 0, duration: 200.ms, curve: Curves.easeOutCubic);
    }

    return TvIconButton(icon: Icon(item.icon), size: TvIconButtonSize.medium, isSecondary: !isSelected, onTap: onTap);
  }

  Widget _buildContentByIndex(BuildContext context, WidgetRef ref, int index) {
    final currentTvTheme = context.tvTheme;
    final myProfileItem = ref.watch(myProfileMenuItemProvider);
    final mySettingsItem = ref.watch(mySettingsMenuItemProvider);

    if (index == myProfileItem.index) {
      return Center(
        child: Text(myProfileItem.title, style: AppTextStyles.t28W600.copyWith(color: currentTvTheme.primaryTextColor)),
      );
    }
    if (index == mySettingsItem.index) {
      return Center(
        child: Text(
          mySettingsItem.title,
          style: AppTextStyles.t28W600.copyWith(color: currentTvTheme.primaryTextColor),
        ),
      );
    }
    if (index == 0) {
      return const FavoritePage();
    } else if (index == 1) {
      return const HotPage();
    } else if (index == 2) {
      return const AreasPage();
    } else if (index == 3) {
      return const FavoriteAreasPage();
    } else if (index == 4) {
      return const TvSearchPage();
    } else if (index == 5) {
      return const HistoryPage();
    }

    final menuList = ref.watch(sideMenuListProvider);
    final menuName = menuList.firstWhere((element) => element.index == index).title;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(menuName, style: AppTextStyles.t28W600.copyWith(color: currentTvTheme.primaryTextColor)),
          AppStyle.vGap24,
          _buildBannerDemo(context),
          AppStyle.vGap32,
          _buildVideoSection(context, "推荐直播间"),
        ],
      ),
    );
  }

  Widget _buildBannerDemo(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    return SizedBox(
      height: 300.sp,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (ctx, i) => Container(
          width: 520.sp,
          margin: EdgeInsets.only(right: 24.sp),
          decoration: BoxDecoration(color: currentTvTheme.cardColor, borderRadius: BorderRadius.circular(12.sp)),
          child: Center(
            child: Text("Banner $i", style: AppTextStyles.t24W600.copyWith(color: currentTvTheme.primaryTextColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context, String title) {
    final currentTvTheme = context.tvTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.t24W600.copyWith(color: currentTvTheme.primaryTextColor)),
        AppStyle.vGap16,
        SizedBox(
          height: 180.sp,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (ctx, i) =>
                TvIconButton(icon: const Icon(Icons.play_arrow), size: TvIconButtonSize.medium, onTap: () {}),
          ),
        ),
      ],
    );
  }
}
