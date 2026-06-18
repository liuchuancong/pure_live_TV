import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';

class TvRefreshList extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoadMore;
  final String memoryKey;
  final Header? header;
  final Footer? footer;

  const TvRefreshList({
    super.key,
    required this.child,
    required this.onRefresh,
    this.onLoadMore,
    required this.memoryKey,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      memoryKey: memoryKey,
      verticalEdge: DpadEdgeBehavior.stop,
      child: EasyRefresh(
        header: header ?? const ClassicHeader(triggerOffset: 70, clamping: true, position: IndicatorPosition.above),
        footer: footer ?? ClassicFooter(triggerOffset: 70, clamping: true, position: IndicatorPosition.behind),
        onRefresh: onRefresh,
        onLoad: onLoadMore,
        child: child,
      ),
    );
  }
}
