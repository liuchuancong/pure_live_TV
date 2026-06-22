import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';

class TvRefreshList extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoadMore;
  final String memoryKey;

  const TvRefreshList({
    super.key,
    required this.child,
    required this.onRefresh,
    this.onLoadMore,
    required this.memoryKey,
  });

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      memoryKey: memoryKey,
      verticalEdge: DpadEdgeBehavior.stop,
      child: EasyRefresh(
        header: ClassicHeader(
          triggerOffset: 50,
          clamping: true,
          position: IndicatorPosition.locator,
          dragText: '',
          armedText: '',
          readyText: '',
          processedText: '',
          noMoreText: '',
          failedText: '刷新失败',
          showText: true,
          showMessage: false,
        ),
        footer: ClassicFooter(
          triggerOffset: 50,
          clamping: true,
          position: IndicatorPosition.locator,
          dragText: '',
          armedText: '',
          readyText: '',
          processedText: '',
          noMoreText: '没有更多频道了',
          failedText: '加载失败',
          showText: true,
          showMessage: false,
        ),
        onRefresh: onRefresh,
        onLoad: onLoadMore,
        child: child,
      ),
    );
  }
}
