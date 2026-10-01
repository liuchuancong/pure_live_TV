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

    // newBV's partition: the server answers -1 for a video that ran to its
    // end, everything else carries the watched seconds.
    final unfinished = _items!.where((item) => item.progress != -1).toList();
    final finished = _items!.where((item) => item.progress == -1).toList();

    return DpadRegion(
      child: ListView(
        padding: EdgeInsets.all(24.ts(context)),
        children: [
          if (unfinished.isNotEmpty) ...[
            _BlockHeader(label: '${i18n('video_toview_unfinished')}（${unfinished.length}）'),
            _BlockGrid(
              items: unfinished,
              onOpen: (item) => openVideoArchive(context, ref, item.archive),
              onLongPress: _remove,
            ),
          ],
          if (finished.isNotEmpty) ...[
            _BlockHeader(label: '${i18n('video_toview_finished')}（${finished.length}）'),
            _BlockGrid(
              items: finished,
              onOpen: (item) => openVideoArchive(context, ref, item.archive),
              onLongPress: _remove,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.ts(context), top: 8.ts(context), bottom: 12.ts(context)),
      child: Text(
        label,
        style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: context.tvTheme.focusColor),
      ),
    );
  }
}

class _BlockGrid extends ConsumerWidget {
  const _BlockGrid({required this.items, required this.onOpen, required this.onLongPress});

  final List<ToViewItem> items;
  final void Function(ToViewItem item) onOpen;
  final void Function(ToViewItem item) onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 12.ts(context)),
      gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final archive = item.archive;
        final percent = item.progress > 0 && archive.duration > 0
            ? (item.progress / archive.duration).clamp(0.0, 1.0)
            : ref.read(videoProgressControllerProvider.notifier).percentOf(archive.bvid);
        return GestureDetector(
          onLongPress: () => onLongPress(item),
          child: VideoCard(
            archive: archive,
            badge: percent > 0 ? '${(percent * 100).toStringAsFixed(0)}%' : '',
            onTap: () => onOpen(item),
          ),
        );
      },
    );
  }
}

/// season's episode page.
