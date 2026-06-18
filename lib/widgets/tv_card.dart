import 'tv_focusable.dart';
import 'package:flutter/material.dart';

class TvCard extends StatelessWidget {
  final String cover;

  final String title;

  final VoidCallback? onTap;

  const TvCard({super.key, required this.cover, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,

      child: SizedBox(
        width: 240,

        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,

              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),

                child: Image.network(cover, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 8),

            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
