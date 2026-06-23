import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TvTabView extends StatelessWidget {
  final String memoryKey;
  final Widget child;
  final DpadEdgeBehavior verticalEdge;
  final DpadEdgeBehavior horizontalEdge;

  const TvTabView({
    super.key,
    required this.memoryKey,
    required this.child,
    this.verticalEdge = DpadEdgeBehavior.stop,
    this.horizontalEdge = DpadEdgeBehavior.stop,
  });

  @override
  Widget build(BuildContext context) {
    return DpadRegion(memoryKey: memoryKey, verticalEdge: verticalEdge, horizontalEdge: horizontalEdge, child: child);
  }
}
