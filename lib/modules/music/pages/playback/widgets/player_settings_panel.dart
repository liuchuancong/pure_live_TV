import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/settings/pages/music_settings_section.dart';

/// picture, the way live_play mounts its own side panels.
class MusicPlayerSettingsPanel extends ConsumerWidget {
  const MusicPlayerSettingsPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.tvTheme.focusColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.ts(context), 14.ts(context), 12.ts(context), 10.ts(context)),
            child: Row(
              children: [
                SizedBox(width: 6.ts(context)),
                Expanded(
                  child: Text(
                    i18n('settings'),
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(8.ts(context), 0, 8.ts(context), 16.ts(context)),
              // The autofocus Focus is what pulls the keyboard into the popup:
              // without it the page's root below keeps the focus and the
              // opened panel looks dead to the remote until a lucky arrow.
              child: Focus(autofocus: true, child: MusicSettingsSectionPage()),
            ),
          ),
        ],
      ),
    );
  }
}
