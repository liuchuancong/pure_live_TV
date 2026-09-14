import 'package:flutter/material.dart';

class TvSection extends StatelessWidget {
  final String title;

  final Widget child;

  const TvSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
}
