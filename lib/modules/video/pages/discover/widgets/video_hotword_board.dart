import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';

/// The idle board: trending words from the search square, the entry newBV's
/// TV search starts from.
class VideoHotwordBoard extends StatelessWidget {
  const VideoHotwordBoard({super.key, required this.hotwords, required this.onPick});

  final List<Hotword> hotwords;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (hotwords.isEmpty) {
      return Center(
        child: Text(
          i18n('music_search_empty_hint'),
          style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
        ),
      );
    }
    return DpadRegion(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.ts(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, size: 26.ts(context), color: accent),
                SizedBox(width: 8.ts(context)),
                Text(
                  i18n('video_search_hotwords'),
                  style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                ),
              ],
            ),
            SizedBox(height: 16.ts(context)),
            Wrap(
              spacing: 12.ts(context),
              runSpacing: 12.ts(context),
              children: [
                for (final (index, word) in hotwords.indexed)
                  TvFocusable(
                    autofocus: index == 0,
                    onTap: () => onPick(word.keyword),
                    builder: (context, focused, child) => AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: EdgeInsets.symmetric(horizontal: 20.ts(context), vertical: 10.ts(context)),
                      decoration: BoxDecoration(
                        color: tvTheme.cardColor,
                        borderRadius: BorderRadius.circular(24.ts(context)),
                        border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}',
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w700,
                              color: index < 3 ? Colors.redAccent : tvTheme.secondaryTextColor,
                            ),
                          ),
                          SizedBox(width: 8.ts(context)),
                          Text(
                            word.keyword,
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
