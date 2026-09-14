import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 背景全屏预览。
///
/// 移植自老项目 `wallpaper_preview_page.dart` 的交互：**任意方向键换一张**，
/// 返回键退出预览 —— 全屏时不给遥控器留任何按钮，避免预览界面被 UI 挡住。
class WallpaperPreviewPage extends ConsumerStatefulWidget {
  const WallpaperPreviewPage({super.key});

  @override
  ConsumerState<WallpaperPreviewPage> createState() => _WallpaperPreviewPageState();
}

class _WallpaperPreviewPageState extends ConsumerState<WallpaperPreviewPage> {
  bool _loading = false;

  Future<void> _next() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await ref.read(backgroundControllerProvider.notifier).getRandomImage();
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) ToastUtil.show(i18nOr('ui_wallpaper_fetch_failed', '获取壁纸失败，换个图源再试'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return TvScaffold(
      showAppBar: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 整屏焦点：任意方向键/确认键都换一张。
          DpadFocusable(
            autofocus: true,
            excludeChildFocus: true,
            effects: const [],
            onSelect: _next,
            onDirection: (_) {
              _next();
              return true;
            },
            child: const SizedBox.expand(),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40.sp,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24.sp),
                  ),
                  child: Text(
                    i18nOr('ui_wallpaper_preview_hint', '方向键换一张 · 返回键退出预览'),
                    style: AppTextStyles.t18W500.copyWith(color: theme.primaryTextColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
