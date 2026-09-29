import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';

import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';

/// The followed users' video feed (bmsc/newBV's dynamics), shared by the
/// music and video home rails: one grid paging the offset-based API.
class UgcDynamicsPage extends ConsumerStatefulWidget {
  const UgcDynamicsPage({super.key});

  @override
  ConsumerState<UgcDynamicsPage> createState() => _UgcDynamicsPageState();
}

class _UgcDynamicsPageState extends ConsumerState<UgcDynamicsPage> {
  final ScrollController _scroll = ScrollController();
  final List<DynamicVideo> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  String _offset = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 && !_loading && _hasMore) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final (rows, nextOffset) = await BilibiliUgcApi.instance.getDynamics(offset: _offset);
      if (!mounted) return;
      setState(() {
        _items.addAll(rows);
        _offset = nextOffset;
        _hasMore = rows.isNotEmpty;
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

    if (_error != null && _items.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_items.isEmpty && _loading) {
      return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    }
    if (_items.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('music_dynamics_empty'), subtitle: '');
    }

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: GridView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(24.ts(context)),
        gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            // The loader owns the cell: a 32.sp ring vanished inside a
            // grid-sized cell, reading as a broken tile.
            if (!_loading) return const SizedBox.shrink();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64.ts(context),
                    height: 64.ts(context),
                    child: CircularProgressIndicator(strokeWidth: 5.sp, color: accent),
                  ),
                  SizedBox(height: 12.ts(context)),
                  Text(
                    i18n('ui_loading'),
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            );
          }
          final item = _items[index];
          // The card carries its own UP/date caption now — only the dynamic's
          // publish time is passed in to override the archive's.
          return MusicVideoCard(
            archive: item.archive,
            pubTime: item.pubTime,
            onTap: () => openVideoArchive(context, ref, item.archive),
          );
        },
      ),
    );
  }
}
