import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// folder cards speak the cover-card visual — the folder's art (its first
/// video's cover) fills the card with a count chip on the corner, the title
/// sits beneath — and OK opens the folder's videos as the video grid.
class VideoFavPane extends ConsumerStatefulWidget {
  const VideoFavPane({super.key});

  @override
  ConsumerState<VideoFavPane> createState() => VideoFavPaneState();
}

class VideoFavPaneState extends ConsumerState<VideoFavPane> {
  List<FavFolder>? _folders;

  /// Folder id → cover, filled as the tiny per-folder lookups land. A folder
  /// with no videos (or a failed lookup) falls back to the icon.
  final Map<int, String> _covers = {};

  String? _error;
  int? _openFolderId;
  List<FavResource>? _resources;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await BilibiliUgcApi.instance.getMyFavFolders();
      if (!mounted) return;
      setState(() => _folders = folders);
      // One first-page lookup per folder, only for the art — the count comes
      // from the folder itself. These run after the grid is up, each card
      // painting its cover as the answer lands.
      await Future.wait([
        for (final folder in folders)
          () async {
            try {
              final resources = await BilibiliUgcApi.instance.getFavResources(folder.id, pageSize: 1);
              if (!mounted) return;
              setState(() {
                _covers[folder.id] = resources.isEmpty ? '' : resources.first.toArchive().cover;
              });
            } catch (_) {
              // A folder without art keeps the fallback icon.
            }
          }(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openFolder(FavFolder folder) async {
    setState(() {
      _openFolderId = folder.id;
      _resources = null;
    });
    try {
      final resources = await BilibiliUgcApi.instance.getFavResources(folder.id, pageSize: 25);
      if (!mounted) return;
      setState(() => _resources = resources);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resources = []);
      ToastUtil.show(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_error != null) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_folders == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');

    if (_openFolderId != null) {
      if (_resources == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 8.ts(context)),
            child: TvButton(
              title: i18n('video_personal_back'),
              icon: Icon(Icons.arrow_back_rounded, size: 22.ts(context)),
              size: TvButtonSize.mini,
              isSecondary: true,
              onTap: () => setState(() => _openFolderId = null),
            ),
          ),
          Expanded(
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: GridView.builder(
                padding: EdgeInsets.all(24.ts(context)),
                gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                itemCount: _resources!.length,
                itemBuilder: (context, index) {
                  final archive = _resources![index].toArchive();
                  return VideoCard(archive: archive, onTap: () => openVideoArchive(context, ref, archive));
                },
              ),
            ),
          ),
        ],
      );
    }

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: GridView.builder(
        padding: EdgeInsets.all(24.ts(context)),
        gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
        itemCount: _folders!.length,
        itemBuilder: (context, index) {
          final folder = _folders![index];
          final cover = _covers[folder.id] ?? '';
          return TvFocusable(
            onTap: () => _openFolder(folder),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.ts(context)),
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: focused ? 0.25 : 0), blurRadius: focused ? 18.sp : 0),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
                          child: cover.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: cover,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 480,
                                  fadeInDuration: Duration.zero,
                                  errorWidget: (_, _, _) => _coverFallback(accent),
                                )
                              : _coverFallback(accent),
                        ),
                        Positioned(
                          right: 8.sp,
                          top: 8.sp,
                          child: TvCoverChip(label: '${folder.mediaCount}'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.sp),
                    child: Text(
                      folder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
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

  Widget _coverFallback(Color accent) => Container(
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.folder_special_outlined, size: 56.sp, color: accent),
  );
}

/// Cloud history, cursor-paged, with the progress bar the server reports.
