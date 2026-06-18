import 'package:pure_live/common/index.dart';
import 'package:pure_live/theme/tv_refresh_list.dart';
import 'package:pure_live/common/base/base_controller.dart';
import 'package:pure_live/common/widgets/app_status_view.dart';
import 'package:pure_live/common/base/base_page_scroll_bone_tv.dart';

class TvBasePageView<C extends BaseTvPageScrollBone<T>, T> extends StatelessWidget {
  final C controller;
  final Widget Function(BuildContext context, List<T> list, ScrollController scrollController) contentBuilder;
  final bool enableRefresh;
  final bool enableLoadMore;
  final bool showScrollToTopBtn;
  final Widget Function(BuildContext context)? notLoginBuilder;
  final Widget Function(BuildContext context, String errorMsg)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  const TvBasePageView({
    super.key,
    required this.controller,
    required this.contentBuilder,
    this.enableRefresh = true,
    this.enableLoadMore = true,
    this.showScrollToTopBtn = true,
    this.notLoginBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主内容区域（正常 Column 布局，无错误Stack）
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 蜂窝网络提示
            Obx(() {
              if (controller.showCellularBanner.value && controller.list.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.signal_cellular_alt_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(i18n("cellular_warning_msg"), style: const TextStyle(fontSize: 13))),
                        TextButton(
                          onPressed: () => BaseController.neverShowCellularBanner = true,
                          child: Text(i18n("never_show"), style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            // 列表内容区域
            Expanded(
              child: Obx(() {
                if (controller.list.isEmpty) {
                  return _buildEmptyView(context);
                }
                return _buildTvContent(context);
              }),
            ),
          ],
        ),

        if (showScrollToTopBtn)
          Positioned(
            right: 24.w,
            bottom: 32.w,
            child: Obx(
              () => AnimatedScale(
                scale: controller.showBackToTop.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: DpadFocusable(
                  effects: const [DpadScaleEffect(scale: 1.1)],
                  onSelect: controller.scrollToTopOrRefresh,
                  child: FloatingActionButton(
                    heroTag: "tv_scroll_top",
                    mini: true,
                    backgroundColor: Theme.of(context).cardColor,
                    child: const Icon(Icons.arrow_upward_rounded),
                    onPressed: () => controller.scrollToTopOrRefresh(), // 仅支持TV焦点
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 空/错误/未登录状态视图
  Widget _buildEmptyView(BuildContext context) {
    late Widget statusWidget;

    if (controller.notLogin.value) {
      statusWidget =
          notLoginBuilder?.call(context) ??
          AppStatusView(
            type: AppStatusType.error,
            icon: Icons.account_circle_outlined,
            title: i18n("login_required_title"),
            subtitle: i18n("login_required_subtitle"),
            buttonText: i18n("go_to_login"),
            onButtonPressed: () => Get.toNamed(RoutePath.kSettingsAccount),
          );
    } else if (controller.pageError.value) {
      statusWidget =
          errorBuilder?.call(context, controller.errorMsg.value) ??
          AppStatusView(
            type: AppStatusType.error,
            icon: Icons.wifi_off_rounded,
            title: i18n("network_error_title"),
            subtitle: controller.errorMsg.value,
            buttonText: i18n("retry"),
            onButtonPressed: () => controller.refreshData(),
          );
    } else if (controller.pageEmpty.value) {
      statusWidget =
          emptyBuilder?.call(context) ?? AppStatusView(type: AppStatusType.empty, title: i18n('no_data'), subtitle: '');
    } else {
      return const Center(child: CircularProgressIndicator());
    }

    return TvRefreshList(
      memoryKey: "tv_empty_list",
      onRefresh: controller.refreshData,
      child: Center(child: statusWidget),
    );
  }

  Widget _buildTvContent(BuildContext context) {
    return TvRefreshList(
      memoryKey: "tv_main_list",
      onRefresh: enableRefresh ? controller.refreshData : () async {},
      onLoadMore: enableLoadMore ? controller.loadMoreData : null,
      child: contentBuilder(context, controller.list, controller.scrollController),
    );
  }
}
