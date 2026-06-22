import 'package:flutter/material.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';

class TvPage extends StatefulWidget {
  final Widget child;

  const TvPage({super.key, required this.child});

  static ScrollController? maybeOf(BuildContext context) {
    return PrimaryScrollController.maybeOf(context);
  }

  @override
  State<TvPage> createState() => _TvPageState();
}

class _TvPageState extends State<TvPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return PrimaryScrollController(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth - 96, minHeight: constraints.maxHeight - 48),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
