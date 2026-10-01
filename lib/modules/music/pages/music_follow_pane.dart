import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';

/// the account's followed uploaders as full-width rows — avatar, name,
/// signature. Tapping opens the UP's space; long-press unfollows against the
/// account and drops the row.
class MusicFollowPane extends ConsumerStatefulWidget {
  const MusicFollowPane({super.key});

  @override
  ConsumerState<MusicFollowPane> createState() => _MusicFollowPaneState();
}

class _MusicFollowPaneState extends ConsumerState<MusicFollowPane> {
  static const int _pageSize = 24;

  List<({int mid, String name, String face, String sign})>? _follows;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final batch = await BilibiliUgcApi.instance.getFollowings(page: _page, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _follows = [...(_follows ?? const []), ...batch];
        _page++;
        _hasMore = batch.length >= _pageSize;
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

  /// Long-press unfollows against the account and drops the row — the same
  /// relationship API the video follow pane uses.
  Future<void> _unfollow(int index) async {
    final follow = _follows?[index];
    if (follow == null) return;
    try {
      await BilibiliUgcApi.instance.setFollowing(follow.mid, follow: false);
      if (!mounted) return;
      setState(() {
        final rows = List.of(_follows!);
        rows.removeAt(index);
        _follows = rows;
      });
      ToastUtil.show(i18n('video_follow_unfollowed'));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    }
  }

  /// Long-press opens an explicit confirm first, so an accidental OK-hold on a
  /// card never silently drops the follow.
  Future<void> _confirmUnfollow(int index) async {
    final follow = _follows?[index];
    if (follow == null) return;
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: follow.name,
        cancelText: i18n('cancel'),
        width: 560.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n('music_unfollow_up'),
              icon: Icon(Icons.person_remove_outlined, size: 26.ts(context)),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(_unfollow(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_error != null) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    final follows = _follows;
    if (follows == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (follows.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('video_follow_empty'), subtitle: '');
    }

    // The UP cards on a grid — the video follow pane's shape: five columns
    // under the sidebar-constrained pane, cells sized taller than the content
    // ever grows (avatar + two ellipsized lines) so a font-scale bump cannot
    // overflow them.
    return GridView.builder(
      padding: EdgeInsets.all(24.ts(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.5,
        crossAxisSpacing: 14.ts(context),
        mainAxisSpacing: 14.ts(context),
      ),
      itemCount: follows.length + (_hasMore || _loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= follows.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadMore();
          });
          return Center(
            child: _loading
                ? SizedBox(
                    width: 28.ts(context),
                    height: 28.ts(context),
                    child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                  )
                : const SizedBox.shrink(),
          );
        }
        final follow = follows[index];
        return TvFocusable(
          onTap: () => UgcUserSpaceRoute(follow.mid, follow.name).push(context),
          onLongPress: () => _confirmUnfollow(index),
          builder: (context, focused, child) => Container(
            padding: EdgeInsets.all(16.ts(context)),
            decoration: BoxDecoration(
              color: focused ? tvTheme.focusedCardColor : tvTheme.cardColor,
              borderRadius: BorderRadius.circular(16.ts(context)),
              border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: follow.face,
                    width: 96.ts(context),
                    height: 96.ts(context),
                    fit: BoxFit.cover,
                    memCacheWidth: 192,
                    placeholder: (_, _) => ColoredBox(color: tvTheme.cardColor),
                    errorWidget: (_, _, _) => ColoredBox(color: tvTheme.cardColor),
                  ),
                ),
                SizedBox(height: 12.ts(context)),
                Text(
                  follow.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                ),
                if (follow.sign.isNotEmpty) ...[
                  SizedBox(height: 4.ts(context)),
                  Text(
                    follow.sign,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w300, color: tvTheme.secondaryTextColor),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
