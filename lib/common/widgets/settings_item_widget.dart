import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';

class SettingsItemWidget extends StatelessWidget {
  final AppFocusNode focusNode;
  final Map<dynamic, String> items;
  final dynamic value;
  final String title;
  final bool autofocus;
  final Function(dynamic) onChanged;
  final bool useFocus;
  final bool selected;
  const SettingsItemWidget({
    required this.focusNode,
    required this.items,
    required this.value,
    required this.title,
    required this.onChanged,
    this.autofocus = false,
    this.selected = false,
    this.useFocus = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HighlightWidget(
      focusNode: focusNode,
      autofocus: autofocus,
      useFocus: useFocus,
      selected: selected,
      borderRadius: AppStyle.radius16,
      onLeftKey: () {
        if (items.isEmpty) return KeyEventResult.handled;
        if (items.keys.first == value) {
          onChanged(items.keys.last);
        } else {
          onChanged(items.keys.elementAt(items.keys.toList().indexOf(value) - 1));
        }
        return KeyEventResult.handled;
      },
      onRightKey: () {
        if (items.isEmpty) return KeyEventResult.handled;
        if (items.keys.last == value) {
          onChanged(items.keys.first);
        } else {
          onChanged(items.keys.elementAt(items.keys.toList().indexOf(value) + 1));
        }
        return KeyEventResult.handled;
      },
      child: Obx(
        () => Padding(
          padding: AppStyle.edgeInsetsA24,
          child: Row(
            children: [
              Text(
                title,
                style: (focusNode.isFoucsed.value || selected) ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
              ),
              const Spacer(),
              if (focusNode.isFoucsed.value || selected && items.isNotEmpty)
                Icon(
                  Icons.chevron_left,
                  size: 40.w,
                  color: focusNode.isFoucsed.value || selected ? Colors.black : Colors.white,
                ),
              AppStyle.hGap12,
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 120.w),
                child: Text(
                  items[value] ?? '',
                  style: focusNode.isFoucsed.value || selected ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
                  textAlign: focusNode.isFoucsed.value || selected ? TextAlign.center : TextAlign.right,
                ),
              ),
              AppStyle.hGap12,
              if (focusNode.isFoucsed.value || selected && items.isNotEmpty)
                Icon(
                  Icons.chevron_right,
                  size: 40.w,
                  color: focusNode.isFoucsed.value || selected ? Colors.black : Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
