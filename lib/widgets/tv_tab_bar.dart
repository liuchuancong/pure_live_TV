import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TvTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final void Function(int index) onTabChange;
  final List<DpadEffect> effects;

  const TvTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChange,
    this.effects = const [DpadScaleEffect(scale: 1.05), DpadBorderEffect(color: Colors.blue, width: 2)],
  });

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.wrap,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;

          return DpadFocusable(
            effects: effects,
            onFocusChange: (focused) {
              if (focused) {
                onTabChange(idx);
              }
            },
            onSelect: () => onTabChange(idx),
            builder: (context, state, child) {
              final isSelected = currentIndex == idx;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: isSelected || state.focused ? FontWeight.bold : FontWeight.normal,
                    color: state.focused ? Colors.blue : (isSelected ? Colors.white : Colors.white70),
                  ),
                ),
              );
            },
            child: const SizedBox.shrink(),
          );
        }).toList(),
      ),
    );
  }
}
