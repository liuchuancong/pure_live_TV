import 'package:pure_live/app/app_focus_node.dart';

class BaseFocusModel {
  final AppFocusNode focusNode = AppFocusNode();
  bool get isFoucsed => focusNode.isFoucsed.value;
}
