import 'package:flutter/material.dart';

class TvLazyWrapper extends StatefulWidget {
  final bool isCurrent;
  final Widget child;

  const TvLazyWrapper({super.key, required this.isCurrent, required this.child});

  @override
  State<TvLazyWrapper> createState() => _TvLazyWrapperState();
}

class _TvLazyWrapperState extends State<TvLazyWrapper> {
  bool _hasBeenLoaded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrent && !_hasBeenLoaded) {
      _hasBeenLoaded = true;
    }

    if (_hasBeenLoaded) {
      return widget.child;
    }

    return const SizedBox.shrink();
  }
}
