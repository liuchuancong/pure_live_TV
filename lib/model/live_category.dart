import 'dart:convert';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/models/index.dart';

class LiveCategory {
  final String name;
  final String id;
  final List<LiveArea> children;
  AppFocusNode moreFocusNode = AppFocusNode();
  LiveCategory({
    required this.id,
    required this.name,
    required this.children,
  });

  @override
  String toString() {
    return json.encode({
      "name": name,
      "id": id,
      "children": children,
    });
  }
}
