import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/video/video_section.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/models/models.dart';


/// A shared UP-space page: the header card (avatar, sign, followers, follow
/// button) over a paged uploads grid. Music opens it from comment/track
/// authors, video from detail cards — one implementation for both.
class UgcUserSpacePage extends ConsumerStatefulWidget {
  const UgcUserSpacePage({super.key, required this.mid, this.name = ''});

  final int mid;
  final String name;

  @override
  ConsumerState<UgcUserSpacePage> createState() => _UgcUserSpacePageState();
}

class _UgcUserSpacePageState extends ConsumerState<UgcUserSpacePage> {
  final ScrollController _scroll = ScrollController();
  UserSpaceInfo? _info;
  final List<MusicArchive> _uploads = [];
  bool _loadingHeader = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  bool _followBusy = false;
  String _order = 'pubdate';

  @override
  void initState() {
    super.initState();
    _loadHeader();
    _loadMore();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 && !_loadingMore && _hasMore) _loadMore();
  }

  Future<void> _loadHeader() async {
    try {
      final info = await BilibiliUgcApi.instance.getUserSpace(widget.mid);
      if (!mounted) return;
      setState(() {
        _info = info;
        _loadingHeader = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingHeader = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final uploads = await BilibiliUgcApi.instance.getUserUploads(widget.mid, page: _page + 1, order: _order);
      if (!mounted) return;
      setState(() {
        _uploads.addAll(uploads);
        _page += 1;
        _hasMore = uploads.length >= 25;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    try {
      await BilibiliUgcApi.instance.setFollowing(widget.mid, follow: !(_info?.isFollowed ?? false));
      if (!mounted) return;
      setState(() => _info = UserSpaceInfo(
        mid: _info!.mid,
        name: _info!.name,
        face: _info!.face,
        sign: _info!.sign,
        followers: _info!.followers,
        following: _info!.following,
        videoCount: _info!.videoCount,
        isFollowed: !_info!.isFollowed,
        level: _info!.level,
      ));
      ToastUtil.show(_info!.isFollowed ? i18n('video_follow_done') : i18n('video_unfollow_done'));
    } catch (_) {
      ToastUtil.show(i18n('video_action_need_login'));
    } finally {
      _followBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvPageScaffold(
      title: _info?.name ?? widget.name,
      child: _loadingHeader
          ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
          : _error != null && _info == null
              ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error)
              : DpadRegion(
                  child: CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      SliverToBoxAdapter(child: _HeaderCard(info: _info!, onToggleFollow: _toggleFollow)),
                      SliverPadding(padding: EdgeInsets.only(top: 12.sp)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.sp),
                          child: Row(
                            children: [
                              Text(
                                '${i18n('video_uploads_title')}（${_info!.videoCount}）',
                                style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                              ),
                              const Spacer(),
                              TvButton(
                                title: i18n(_order == 'pubdate' ? 'video_order_newest' : 'video_order_most_played'),
                                icon: Icon(
                                  _order == 'pubdate' ? Icons.schedule_rounded : Icons.local_fire_department_outlined,
                                  size: 22.sp,
                                ),
                                size: TvButtonSize.mini,
                                isSecondary: true,
                                onTap: () {
                                  setState(() {
                                    _order = _order == 'pubdate' ? 'click' : 'pubdate';
                                    _uploads.clear();
                                    _page = 0;
                                    _hasMore = true;
                                  });
                                  _loadMore();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(padding: EdgeInsets.only(top: 12.sp)),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.sp),
                        sliver: SliverGrid(
                          gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                          delegate: SliverChildBuilderDelegate(
                            childCount: _uploads.length + (_hasMore ? 1 : 0),
                            (context, index) {
                              if (index >= _uploads.length) {
                                return Center(
                                  child: _loadingMore
                                      ? SizedBox(
                                          width: 32.sp,
                                          height: 32.sp,
                                          child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                                        )
                                      : const SizedBox.shrink(),
                                );
                              }
                              final upload = _uploads[index];
                              return _UploadCard(archive: upload, mid: widget.mid);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.info, required this.onToggleFollow});

  final UserSpaceInfo info;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.sp),
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: tvTheme.cardColor,
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Row(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: info.face,
              width: 96.sp,
              height: 96.sp,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(Icons.person_rounded, size: 96.sp, color: tvTheme.secondaryTextColor),
            ),
          ),
          SizedBox(width: 20.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor)),
                if (info.sign.isNotEmpty) ...[
                  SizedBox(height: 6.sp),
                  Text(
                    info.sign,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                  ),
                ],
                SizedBox(height: 8.sp),
                Row(
                  children: [
                    _Stat(label: i18n('video_followers'), value: readableCount(info.followers.toString())),
                    SizedBox(width: 24.sp),
                    _Stat(label: i18n('video_following'), value: readableCount(info.following.toString())),
                    SizedBox(width: 24.sp),
                    _Stat(label: i18n('video_uploads_title'), value: readableCount(info.videoCount.toString())),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16.sp),
          TvButton(
            title: i18n(info.isFollowed ? 'video_unfollow' : 'video_follow'),
            icon: Icon(info.isFollowed ? Icons.done_rounded : Icons.add_rounded, size: 24.sp),
            size: TvButtonSize.mini,
            isSecondary: info.isFollowed,
            onTap: onToggleFollow,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor)),
        Text(label, style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor)),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.archive, required this.mid});

  final MusicArchive archive;
  final int mid;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TvFocusable(
      onTap: () => openVideoArchive(context, ref, archive),
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: context.tvTheme.cardColor,
          borderRadius: BorderRadius.circular(14.sp),
          border: Border.all(
            color: focused ? context.tvTheme.focusColor : Colors.transparent,
            width: 2.sp,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.sp)),
                child: CachedNetworkImage(
                  imageUrl: archive.cover,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 480,
                  errorWidget: (_, _, _) => Container(color: Colors.black26),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: Text(
                archive.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: context.tvTheme.primaryTextColor),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

