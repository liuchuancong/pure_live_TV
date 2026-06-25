import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvQwerKeyboard extends StatelessWidget {
  const TvQwerKeyboard({super.key, required this.onKeyTap, required this.onDeleteTap, required this.onClearTap});

  final Function(String) onKeyTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onClearTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    // 完全复刻 onscreen_keyboard 的三行标准 26 键 + 数字动作键矩阵
    final List<List<Map<String, String>>> rows = [
      [
        {'d': '1', 'v': '1'},
        {'d': '2', 'v': '2'},
        {'d': '3', 'v': '3'},
        {'d': '4', 'v': '4'},
        {'d': '5', 'v': '5'},
        {'d': '6', 'v': '6'},
        {'d': '7', 'v': '7'},
        {'d': '8', 'v': '8'},
        {'d': '9', 'v': '9'},
        {'d': '0', 'v': '0'},
      ],
      [
        {'d': 'Q', 'v': 'Q'},
        {'d': 'W', 'v': 'W'},
        {'d': 'E', 'v': 'E'},
        {'d': 'R', 'v': 'R'},
        {'d': 'T', 'v': 'T'},
        {'d': 'Y', 'v': 'Y'},
        {'d': 'U', 'v': 'U'},
        {'d': 'I', 'v': 'I'},
        {'d': 'O', 'v': 'O'},
        {'d': 'P', 'v': 'P'},
      ],
      [
        {'d': 'A', 'v': 'A'},
        {'d': 'S', 'v': 'S'},
        {'d': 'D', 'v': 'D'},
        {'d': 'F', 'v': 'F'},
        {'d': 'G', 'v': 'G'},
        {'d': 'H', 'v': 'H'},
        {'d': 'J', 'v': 'J'},
        {'d': 'K', 'v': 'K'},
        {'d': 'L', 'v': 'L'},
        {'d': '退格', 'v': 'DEL'},
      ],
      [
        {'d': 'Z', 'v': 'Z'},
        {'d': 'X', 'v': 'X'},
        {'d': 'C', 'v': 'C'},
        {'d': 'V', 'v': 'V'},
        {'d': 'B', 'v': 'B'},
        {'d': 'N', 'v': 'N'},
        {'d': 'M', 'v': 'M'},
        {'d': '清空', 'v': 'CLR'},
      ],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((keyInfo) {
              final isAction = keyInfo['v'] == 'DEL' || keyInfo['v'] == 'CLR';

              final List<DpadEffect> effects = [
                DpadScaleEffect(scale: 1.08, duration: const Duration(milliseconds: 100)),
                DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.8),
                DpadCustomEffect((ctx, state, _) {
                  final isFocused = state.focused;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: isAction ? 64.sp : 42.sp,
                    height: 44.sp,
                    decoration: BoxDecoration(
                      color: isFocused
                          ? tvTheme.focusedCardColor
                          : (isAction ? tvTheme.cardColor.withValues(alpha: 0.5) : tvTheme.cardColor),
                      borderRadius: BorderRadius.circular(10.sp),
                      border: Border.all(color: isFocused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
                    ),
                    child: Center(
                      child: Text(
                        keyInfo['d']!,
                        style: AppTextStyles.t18W600.copyWith(
                          color: isFocused ? tvTheme.backgroundColor : tvTheme.primaryTextColor,
                          fontSize: isAction ? 14.sp : 18.sp,
                        ),
                      ),
                    ),
                  );
                }),
              ];

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.sp),
                child: DpadFocusable(
                  onSelect: () {
                    if (keyInfo['v'] == 'CLR') {
                      onClearTap();
                    } else if (keyInfo['v'] == 'DEL') {
                      onDeleteTap();
                    } else {
                      onKeyTap(keyInfo['v']!);
                    }
                  },
                  effects: effects,
                  child: const SizedBox(),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
