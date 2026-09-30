import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/core/utils/dpad_long_press_gate.dart';
import 'package:pure_live/core/theme/typography/app_font_scale.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/area_images/area_image_matcher.dart';

class TvAreaCard extends StatefulWidget {
  const TvAreaCard({super.key, required this.area, required this.onTap, required this.onLongPress});

  final LiveArea area;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<TvAreaCard> createState() => _TvAreaCardState();
}

class _TvAreaCardState extends State<TvAreaCard> {
  /// Keeps a long press from also being reported as a select — see
  /// [DpadLongPressGate]. The card is stateful for this alone.
  final DpadLongPressGate _longPressGate = DpadLongPressGate();

  @override
  Widget build(BuildContext context) {
    final LiveArea area = widget.area;
    final tvTheme = context.tvTheme;
    final displayImageUrl = area.areaPic;

    final borderRadius = BorderRadius.circular(18.ts(context));
    final imageRadius = BorderRadius.circular(12.ts(context));
    // The label grows with the app font setting, so the room it needs and the
    // gap above it have to grow with it too.
    final double textScale = TvTextScale.factorOf(context);

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.04,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      // Light palette: a soft 12px halo smears on white; use a crisp ring.
      tvTheme.isLight
          ? DpadGlowEffect(color: tvTheme.focusColor, opacity: 1, spreadRadius: 2.ts(context), blurRadius: 0)
          : DpadGlowEffect(
              color: tvTheme.focusColor,
              opacity: 1,
              spreadRadius: 1.ts(context),
              blurRadius: 12.0.ts(context),
            ),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final bgColor = tvTheme.backgroundColor;
        final titleColor = tvTheme.primaryTextColor;

        return AnimatedContainer(
          duration: TvFocusStyle.focusDuration(isFocused),
          curve: TvFocusStyle.curve,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: isFocused ? tvTheme.focusColor : Colors.transparent, width: 2.ts(context)),
          ),
          child: Padding(
            padding: EdgeInsets.all(9.ts(context)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // How many lines of the label this cell can hold. The name is
                // sized by its text, so a cell too small for two lines would
                // paint the second one over the artwork: it gets one ellipsised
                // line instead. The line height is exact — the style pins
                // `height: 1.15` and the name is 17 design px (the same base
                // the style below uses), so a line is `fontSize * 1.15` at the
                // scale the text is drawn at.
                final double nameLineHeight = 17.ts(context) * 1.15 * textScale;
                final double nameGap = 8.ts(context);
                final int nameLines = constraints.maxHeight - nameGap >= nameLineHeight * 2 ? 2 : 1;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The artwork is what flexes: it takes whatever height is left
                    // after the name, so an enlarged app font shrinks the tile
                    // instead of pushing the label out of the cell.
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: imageRadius,
                            clipBehavior: Clip.antiAlias,
                            child: displayImageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: displayImageUrl,
                                    cacheManager: CustomImageCacheManager.instance,
                                    // Area artwork renders inside a small card: decode at that
                                    // size and keep the cached copy bounded.
                                    memCacheWidth: 320,
                                    fit: BoxFit.contain,
                                    imageBuilder: (context, imageProvider) {
                                      // Clip the actual decoded image, not just its parent.
                                      return ClipRRect(
                                        borderRadius: imageRadius,
                                        clipBehavior: Clip.antiAlias,
                                        child: Image(
                                          image: imageProvider,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                    placeholder: (context, url) => AppStatusView(
                                      type: AppStatusType.loading,
                                      title: "",
                                      subtitle: "",
                                      isMini: true,
                                    ),
                                    errorWidget: (context, url, error) {
                                      // A dead/expired picture (borrowed matches included)
                                      // is dropped from the match cache; the next category
                                      // refresh picks another one.
                                      AreaImageMatcher.instance.reportBroken(url);
                                      return AppStatusView(
                                        type: AppStatusType.error,
                                        title: "",
                                        subtitle: "",
                                        isMini: true,
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(Icons.live_tv_rounded, size: 40.ts(context), color: titleColor),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: nameGap),
                    // The name is sized by the text it holds, never by a fixed
                    // box: the old `SizedBox(height: 32.ts(context))` clipped a two-line
                    // name even at 100% and hid it completely once the app font
                    // was enlarged. [nameLines] keeps it bounded either way.
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.ts(context)),
                      child: Text(
                        area.areaName,
                        maxLines: nameLines,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.t20.copyWith(
                          color: titleColor,
                          fontSize: (17 * AppFontScale.user).sp,
                          height: 1.15,
                          fontWeight: isFocused ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    ];

    return DpadFocusable(
      autofocus: false,
      effects: effects,
      // `DpadFocusable` already reveals the focused card through
      // `DpadScroll.ensureVisible` (padded, and it walks every scrollable
      // ancestor). The extra `Scrollable.ensureVisible` here animated to a
      // second, different offset and made the grid jitter while moving.
      onSelect: () {
        // The long press owns this press; its release must not open the area.
        if (_longPressGate.swallowSelect()) return;
        widget.onTap();
      },
      onLongSelect: () {
        _longPressGate.markLongPress();
        widget.onLongPress();
      },
      child: const SizedBox(),
    );
  }
}
