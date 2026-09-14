import 'package:flutter/material.dart';

class TvSettingsCard extends StatelessWidget {
  final List<Widget> children;

  const TvSettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validChildren = children.where((w) => w is! SizedBox).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Column(
        children: List.generate(validChildren.length, (index) {
          return Column(
            children: [
              validChildren[index],
              if (index != validChildren.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
            ],
          );
        }),
      ),
    );
  }
}
