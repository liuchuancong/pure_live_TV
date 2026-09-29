import 'package:flutter/material.dart';

class SubtreeReviver extends StatefulWidget {
  final Widget child;

  const SubtreeReviver({super.key, required this.child});

  @override
  // ignore: library_private_types_in_public_api
  _IterumState createState() => _IterumState();

  static void revive(BuildContext context) {
    context.findAncestorStateOfType<_IterumState>()!.revive();
  }
}

class _IterumState extends State<SubtreeReviver> {
  Key _key = UniqueKey();
  void revive() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
