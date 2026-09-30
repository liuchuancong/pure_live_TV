import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// Movie results: PGC seasons, straight into the season page.
class VideoPgcResults extends ConsumerStatefulWidget {
  const VideoPgcResults({super.key, required this.keyword});

  final String keyword;

  @override
  ConsumerState<VideoPgcResults> createState() => _VideoPgcResultsState();
}

class _VideoPgcResultsState extends ConsumerState<VideoPgcResults> {
  List<SearchPgcItem> _seasons = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final seasons = await BilibiliUgcApi.instance.searchPgc(widget.keyword);
      if (!mounted) return;
      setState(() {
        _seasons = seasons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_loading && _seasons.isEmpty) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_error != null && _seasons.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: GridView.builder(
        padding: EdgeInsets.all(24.ts(context)),
        gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
        itemCount: _seasons.length,
        itemBuilder: (context, index) {
          final season = _seasons[index];
          return TvFocusable(
            onTap: () => VideoSeasonRoute(
              PgcItem(seasonId: season.seasonId, title: season.title, cover: season.cover),
            ).push(context),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(14.ts(context)),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.ts(context)),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14.ts(context))),
                      child: CachedNetworkImage(
                        imageUrl: season.cover,
                        fit: BoxFit.cover,
                        memCacheWidth: 480,
                        errorWidget: (_, _, _) => Container(color: Colors.black26),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.ts(context)),
                      child: Text(
                        season.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
