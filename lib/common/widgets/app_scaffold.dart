import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff141e30),
                  Color(0xff243b55),
                  Color(0xff141e30),
                ],
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
