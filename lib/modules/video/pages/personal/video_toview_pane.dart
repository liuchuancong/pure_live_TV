import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';

class VideoToViewPane extends ConsumerStatefulWidget {
  const VideoToViewPane({super.key});

  @override
  ConsumerState<VideoToViewPane> createState() => VideoToViewPaneState();
}

class VideoToViewPaneState extends ConsumerState<VideoToViewPane> {
  List<ToViewItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await BilibiliUgcApi.instance.getToView();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _remove(ToViewItem item) async {
    try {
      await BilibiliUgcApi.instance.removeFromView(item.archive.aid);
      _load();
    } catch (_) {
      ToastUtil.show(i18n('video_action_need_login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_items == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_items!.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('video_toview_empty'), subtitle: '');
    }

    return DpadRegion(
      child: GridView.builder(
        padding: EdgeInsets.all(24.ts(context)),
        gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final archive = _items![index].archive;
          final progress = ref.read(videoProgressControllerProvider.notifier).percentOf(archive.bvid);
          return GestureDetector(
            onLongPress: () => _remove(_items![index]),
            child: VideoCard(
              archive: archive,
              badge: progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : '',
              onTap: () => openVideoArchive(context, ref, archive),
            ),
          );
        },
      ),
    );
  }
}

/// season's episode page.
