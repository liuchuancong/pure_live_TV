import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/models/models.dart';

/// User results: a list row per UP, opening the shared user-space page.
class VideoUserResults extends ConsumerStatefulWidget {
  const VideoUserResults({super.key,required this.keyword});

  final String keyword;

  @override
  ConsumerState<VideoUserResults> createState() => _VideoUserResultsState();
}

class _VideoUserResultsState extends ConsumerState<VideoUserResults> {
  final List<SearchUserItem> _users = [];
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
      final users = await BilibiliUgcApi.instance.searchUsers(widget.keyword);
      if (!mounted) return;
      setState(() {
        _users.addAll(users);
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

    if (_loading && _users.isEmpty) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_error != null && _users.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    return DpadRegion(
      child: ListView.builder(
        padding: EdgeInsets.all(24.sp),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return TvFocusable(
            onTap: () => UgcUserSpaceRoute(user.mid, user.uname).push(context),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.sp),
              padding: EdgeInsets.all(14.sp),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.uname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                        ),
                        if (user.sign.isNotEmpty)
                          Text(
                            user.sign,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${readableCount(user.fans.toString())} ${i18n('video_followers')}',
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
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

/// Movie results: PGC seasons, straight into the season page.
