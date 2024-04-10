import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';

class SettingsItemWidget extends StatelessWidget {
  final AppFocusNode foucsNode;
  final Map<dynamic, String> items;
  final dynamic value;
  final String title;
  final bool autofocus;
  final Function(dynamic) onChanged;
  const SettingsItemWidget({
    required this.foucsNode,
    required this.items,
    required this.value,
    required this.title,
    required this.onChanged,
    this.autofocus = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HighlightWidget(
      focusNode: foucsNode,
      autofocus: autofocus,
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
      onTap: () {
        SmartDialog.showToast("请左右切换选择");
      },
      child: Obx(
        () => Padding(
          padding: AppStyle.edgeInsetsA24,
          child: Row(
            children: [
              Text(
                title,
                style: foucsNode.isFoucsed.value ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
              ),
              const Spacer(),
              if (foucsNode.isFoucsed.value && items.isNotEmpty)
                Icon(
                  Icons.chevron_left,
                  size: 40.w,
                  color: foucsNode.isFoucsed.value ? Colors.black : Colors.white,
                ),
              AppStyle.hGap12,
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 120.w),
                child: Text(
                  items[value] ?? '',
                  style: foucsNode.isFoucsed.value ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
                  textAlign: foucsNode.isFoucsed.value ? TextAlign.center : TextAlign.right,
                ),
              ),
              AppStyle.hGap12,
              if (foucsNode.isFoucsed.value && items.isNotEmpty)
                Icon(
                  Icons.chevron_right,
                  size: 40.w,
                  color: foucsNode.isFoucsed.value ? Colors.black : Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
