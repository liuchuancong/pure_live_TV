import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';

typedef FocusOnKeyDownCallback = KeyEventResult Function();

/// 高亮组件
class HighlightWidget extends StatelessWidget {
  final AppFocusNode focusNode;
  final Widget child;
  final FocusOnKeyDownCallback? onUpKey;
  final FocusOnKeyDownCallback? onDownKey;
  final FocusOnKeyDownCallback? onLeftKey;
  final FocusOnKeyDownCallback? onRightKey;
  final Function(bool)? onFocusChange;
  final Function()? onTap;
  final Color foucsedColor;
  final Color color;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final double order;
  final bool selected;
  final bool useOtherController;
  final bool useFocus;
  const HighlightWidget({
    required this.focusNode,
    required this.child,
    this.onUpKey,
    this.onDownKey,
    this.onLeftKey,
    this.onRightKey,
    this.onFocusChange,
    this.onTap,
    this.useOtherController = false,
    this.autofocus = false,
    this.selected = false,
    this.borderRadius,
    this.order = 0.0,
    this.color = Colors.transparent,
    this.foucsedColor = Colors.white,
    this.useFocus = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    var themeColor = HexColor(settings.themeColorSwitch.value);
    return useFocus
        ? FocusTraversalOrder(
            order: NumericFocusOrder(order),
            child: Focus(
              focusNode: focusNode,
              autofocus: autofocus,
              onFocusChange: onFocusChange,
              onKeyEvent: (node, e) {
                if (e is KeyDownEvent) {
                  if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
                    return onRightKey?.call() ?? KeyEventResult.ignored;
                  }
                  if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    return onLeftKey?.call() ?? KeyEventResult.ignored;
                  }
                  if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                    return onUpKey?.call() ?? KeyEventResult.ignored;
                  }
                  if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                    return onDownKey?.call() ?? KeyEventResult.ignored;
                  }
                  if (e.logicalKey == LogicalKeyboardKey.enter ||
                      e.logicalKey == LogicalKeyboardKey.select ||
                      e.logicalKey == LogicalKeyboardKey.space) {
                    return onTap?.call() ?? KeyEventResult.ignored;
                  }
                }

                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                onTap: onTap,
                child: Obx(
                  () => AnimatedScale(
                    scale: focusNode.isFoucsed.value ? 1.00 : 0.98,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          boxShadow: focusNode.isFoucsed.value
                              ? [
                                  BoxShadow(
                                    blurRadius: 6.w,
                                    spreadRadius: 2.w,
                                    color: themeColor,
                                    //color: Color.fromARGB(255, 255, 120, 167),
                                  )
                                ]
                              : null,
                          color: (focusNode.isFoucsed.value || selected) ? foucsedColor : color,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : GestureDetector(
            onTap: onTap,
            child: AnimatedScale(
              scale: selected ? 1.00 : 0.98,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              blurRadius: 6.w,
                              spreadRadius: 2.w,
                              color: themeColor,
                              //color: Color.fromARGB(255, 255, 120, 167),
                            )
                          ]
                        : null,
                    color: selected ? foucsedColor : color,
                  ),
                  child: child,
                ),
              ),
            ),
          );
  }
}
