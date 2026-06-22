import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension RouterExt on BuildContext {
  Future<T?> pushPage<T>(String path, {Object? extra}) {
    return push<T>(path, extra: extra);
  }

  void back<T extends Object?>([T? result]) {
    pop(result);
  }

  void closeDialog<T extends Object?>([T? result]) {
    Navigator.of(this, rootNavigator: true).pop(result);
  }
}
