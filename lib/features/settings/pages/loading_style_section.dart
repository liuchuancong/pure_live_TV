import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/index.dart';

/// Loading animation picker.
///
/// A list of names is useless for choosing an animation, so every style is
/// rendered as a live preview and the whole choice lives on its own page (the
/// desktop app's `LoadingStyleSettingsPage`).
class LoadingStyleSectionPage extends ConsumerWidget {
  const LoadingStyleSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final Color color = themeState.loadingStyleColor ?? tvTheme.focusColor;
    final List<Map<String, String>> styles = AppConsts.allStyles;

    return TvScaffold(
      title: i18n('change_loading_style'),
      child: GridView.builder(
        padding: EdgeInsets.all(16.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 12.sp,
          crossAxisSpacing: 12.sp,
          childAspectRatio: 1.05,
        ),
        itemCount: styles.length,
        itemBuilder: (context, index) {
          final Map<String, String> style = styles[index];
          final String key = style['key'] ?? 'default';
          return _LoadingStyleTile(
            styleKey: key,
            name: loadingStyleName(style),
            color: color,
            active: themeState.loadingStyle == key,
            onTap: () => theme.updateSettings(themeState.copyWith(loadingStyle: key)),
          );
        },
      ),
    );
  }
}

/// Localized name of a style entry, falling back to its English name.
String loadingStyleName(Map<String, String> style) {
  final String localized = style['nameZh'] ?? '';
  final String english = style['nameEn'] ?? '';
  if (localized.isEmpty) return english;
  return i18nExists(localized) ? i18n(localized) : (english.isNotEmpty ? english : localized);
}

class _LoadingStyleTile extends StatelessWidget {
  const _LoadingStyleTile({
    required this.styleKey,
    required this.name,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String styleKey;
  final String name;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return DpadFocusable(
      onSelect: onTap,
      builder: (context, state, child) {
        final bool focused = state.focused;
        return Container(
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusColor.withValues(alpha: 0.22) : Colors.transparent,
            border: Border.all(
              color: focused || active ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.25),
              width: focused || active ? 2.sp : 1.sp,
            ),
          ),
          padding: EdgeInsets.all(8.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 52.sp,
                child: Center(
                  child: styleKey == 'default'
                      // The built-in ring is not one of the packaged animations.
                      ? SizedBox(
                          width: 40.sp,
                          height: 40.sp,
                          child: CircularProgressIndicator(value: 0.7, color: color, strokeWidth: 4.sp),
                        )
                      : buildLoadingStylePreview(style: styleKey, color: color, size: 44.sp, theme: tvTheme),
                ),
              ),
              SizedBox(height: 6.sp),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14W500.copyWith(
                  color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
