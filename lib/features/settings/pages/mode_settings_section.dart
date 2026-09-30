import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/modules/vod/index.dart';

class ModeSettingsSectionPage extends ConsumerWidget {
  const ModeSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appModeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('mode_settings')),
        TvSettingsCard(
          children: [
            _ModeOption(
              icon: Icons.live_tv_rounded,
              label: i18n('mode_live'),
              selected: current == AppMode.live,
              onTap: () => _switchMode(ref, AppMode.live),
            ),
            _ModeOption(
              icon: Icons.movie_outlined,
              label: i18n('mode_video'),
              selected: current == AppMode.video,
              onTap: () => _switchMode(ref, AppMode.video),
            ),
            _ModeOption(
              icon: Icons.library_music_outlined,
              label: i18n('mode_music'),
              selected: current == AppMode.music,
              onTap: () => _switchMode(ref, AppMode.music),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _switchMode(WidgetRef ref, AppMode mode) async {
    final current = ref.read(appModeControllerProvider);
    if (mode == current) return;
    await ref.read(musicPlayerControllerProvider.notifier).stop();
    ref.read(appModeControllerProvider.notifier).setMode(mode);
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 20.ts(context), vertical: 16.ts(context)),
          decoration: BoxDecoration(
            color: selected
                ? tvTheme.focusColor
                : (focused ? tvTheme.focusColor.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(12.ts(context)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28.ts(context), color: selected ? Colors.white : tvTheme.focusColor),
              SizedBox(width: 16.ts(context)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t20.copyWith(
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : tvTheme.primaryTextColor,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_rounded, size: 28.ts(context), color: Colors.white),
            ],
          ),
        );
      },
    );
  }
}
