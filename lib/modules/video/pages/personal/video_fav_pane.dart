import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class VideoFavPane extends ConsumerStatefulWidget {
  const VideoFavPane({super.key});

  @override
  ConsumerState<VideoFavPane> createState() => VideoFavPaneState();
}

class VideoFavPaneState extends ConsumerState<VideoFavPane> {
  List<FavFolder>? _folders;
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
          return TvFocusable(
            onTap: () => _openFolder(folder),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.all(16.ts(context)),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.ts(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.folder_special_outlined, size: 40.ts(context), color: accent),
                  SizedBox(height: 10.ts(context)),
                  Expanded(
                    child: Text(
                      folder.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                    ),
                  ),
                  Text(
                    '${folder.mediaCount} ${i18n('music_tracks_unit')}',
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
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

/// Cloud history, cursor-paged, with the progress bar the server reports.
