import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
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
        padding: EdgeInsets.all(24.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16.w,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.95,
        ),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Center(
              child: _loading
                  ? SizedBox(
                      width: 32.sp,
                      height: 32.sp,
                      child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                    )
                  : const SizedBox.shrink(),
            );
          }
          final item = _items[index];
          return Column(
            children: [
              Expanded(
                child: MusicVideoCard(
                  archive: item.archive,
                  onTap: () => VideoDetailRoute(item.archive).push(context),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4.sp),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.archive.upName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                      ),
                    ),
                    Text(
                      item.pubTime,
                      style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
