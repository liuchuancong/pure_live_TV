import 'package:flutter/material.dart';
import 'package:pure_live/core/widgets/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/core/theme/tv_text_scale.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';

/// The sources inside one API group.
///
/// Picking a row opens the fullscreen preview, which downloads a picture and
/// offers next image until the user commits one as the background.
class WallpaperApiGroupPage extends StatelessWidget {
  const WallpaperApiGroupPage({super.key, required this.group});

  final WallpaperApiGroup group;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: group.localizedName(Localizations.localeOf(context).languageCode),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.ts(context), vertical: 12.ts(context)),
        itemCount: group.sources.length,
        itemBuilder: (context, index) {
          final source = group.sources[index];
          return TvSettingsMenuTile<void>(
            title: source.name,
            subtitle: source.host,
            leading: NumberLeading(index + 1),
            onTap: () => WallpaperPreviewRoute(WallpaperPreviewArgs.api(source, title: source.name)).push(context),
          );
        },
      ),
    );
  }
}
