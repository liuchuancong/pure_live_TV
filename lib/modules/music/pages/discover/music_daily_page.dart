import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/modules/music/services/daily_recommendation_service.dart';

/// seed related-video searches, one music pick per seed, cached for the day.
/// The folder button re-pins the source, a card's long press re-rolls one slot.
class MusicDailyPage extends ConsumerStatefulWidget {
  const MusicDailyPage({super.key});

  @override
  ConsumerState<MusicDailyPage> createState() => MusicDailyPageState();
}

class MusicDailyPageState extends ConsumerState<MusicDailyPage> {
  List<MusicArchive>? _recs;
  bool _loading = true;
  bool _lock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_lock) return;
    _lock = true;
    if (mounted) setState(() => _loading = true);
    final recs = await DailyRecommendationService.dailyRecommendations(force: force);
    if (!mounted) return;
    setState(() {
      if (recs != null) _recs = recs;
      _loading = false;
      _lock = false;
    });
  }

  /// One slot re-rolls from a fresh folder seed; the day's cache follows.
  Future<void> _regenerateAt(int index) async {
    final fresh = await DailyRecommendationService.regenerateOne(
      existingBvids: [for (final v in _recs ?? const <MusicArchive>[]) v.bvid],
    );
    if (!mounted) return;
    if (fresh == null) {
      ToastUtil.show(i18n('music_daily_no_more'));
      return;
    }
    setState(() {
      final recs = [...?_recs];
      if (index < recs.length) recs[index] = fresh;
      _recs = recs;
    });
    unawaited(DailyRecommendationService.saveCache(_recs ?? const []));
    ToastUtil.show(i18n('music_daily_rerolled'));
  }

  Future<void> _pickFolder() async {
    try {
      final folders = await BilibiliUgcApi.instance.getMyFavFolders();
      if (!mounted) return;
      final current = DailyRecommendationService.defaultFolder()?.id;
      await TvDialogUtils.show<void>(
        context: context,
        builder: (_) => TvDialog(
          title: i18n('music_pick_folder'),
          cancelText: i18n('cancel'),
          width: 640.ts(context),
          child: SizedBox(
            height: 480.ts(context),
            child: folders.isEmpty
                ? Center(
                    child: Text(
                      i18n('music_no_folders'),
                      style: AppTextStyles.t16.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.tvTheme.secondaryTextColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final fav = folders[index];
                      return TvDialogOptionTile(
                        title: fav.title,
                        subtitle: '${fav.mediaCount}',
                        selected: current == fav.id,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(DailyRecommendationService.setDefaultFolder(fav));
                          _load(force: true);
                        },
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('load_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = DailyRecommendationService.defaultFolder();
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(24.ts(context), 16.ts(context), 24.ts(context), 8.ts(context)),
      child: Row(
        children: [
          TvButton(
            title: folder?.title ?? i18n('music_pick_folder'),
            icon: Icon(Icons.folder_outlined, size: 24.ts(context)),
            size: TvButtonSize.mini,
            isSecondary: true,
            onTap: _pickFolder,
          ),
          const Spacer(),
          TvButton(
            title: i18n('music_regenerate'),
            icon: Icon(Icons.refresh_rounded, size: 24.ts(context)),
            size: TvButtonSize.mini,
            isSecondary: true,
            onTap: folder == null || _loading ? null : () => _load(force: true),
          ),
        ],
      ),
    );

    if (folder == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off_outlined, size: 72.ts(context), color: accent.withValues(alpha: 0.5)),
                  SizedBox(height: 14.ts(context)),
                  Text(
                    i18n('music_daily_need_folder'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final recs = _recs ?? const <MusicArchive>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Expanded(
          child: _loading && recs.isEmpty
              ? Center(
                  child: AppStatusView(type: AppStatusType.loading, title: '', subtitle: ''),
                )
              : recs.isEmpty
              ? Center(
                  child: AppStatusView(type: AppStatusType.empty, title: i18n('music_daily_empty')),
                )
              : DpadRegion(
                  horizontalEdge: DpadEdgeBehavior.leave,
                  child: GridView.builder(
                    padding: EdgeInsets.all(24.ts(context)),
                    gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                    itemCount: recs.length,
                    itemBuilder: (context, index) {
                      final archive = recs[index];
                      return MusicVideoCard(
                        archive: archive,
                        onTap: () => MusicArchiveRoute(archive).push(context),
                        onLongPress: () => _confirmReroll(index),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmReroll(int index) async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_re_recommend'),
        cancelText: i18n('cancel'),
        width: 560.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n('music_re_recommend'),
              icon: Icon(Icons.refresh_rounded, size: 26.ts(context)),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                _regenerateAt(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}
