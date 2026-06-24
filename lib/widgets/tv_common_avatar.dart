import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvCommonAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double? radius;
  final String? fallbackName;
  const TvCommonAvatar({super.key, required this.avatarUrl, this.radius, this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final double r = radius ?? 20.sp;
    final double size = r * 2;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    Widget fallback() {
      final String text = (fallbackName != null && fallbackName!.isNotEmpty)
          ? fallbackName!.characters.first.toUpperCase()
          : '';
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: tvTheme.secondaryTextColor.withValues(alpha: 0.25)),
        child: Text(
          text,
          style: TextStyle(fontSize: r * 0.8, fontWeight: FontWeight.bold, color: tvTheme.primaryTextColor),
        ),
      );
    }

    if (!hasAvatar) return fallback();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: tvTheme.secondaryTextColor.withValues(alpha: 0.15)),
          errorWidget: (_, _, _) => fallback(),
        ),
      ),
    );
  }
}
