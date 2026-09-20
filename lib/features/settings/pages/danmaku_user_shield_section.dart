import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Blocked danmaku users, the keyword page's twin: its own phone QR
/// ([WebRemoteRouter.danmakuUsers]), add dialog and chip cloud. The two lists
/// look and behave alike but never share a page, so each QR and each web form
/// edits exactly one of them.
class DanmakuUserShieldSectionPage extends ConsumerStatefulWidget {
  const DanmakuUserShieldSectionPage({super.key});

  @override
  ConsumerState<DanmakuUserShieldSectionPage> createState() => DanmakuUserShieldSectionPageState();
}

class DanmakuUserShieldSectionPageState extends ConsumerState<DanmakuUserShieldSectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initRemote());
  }

  void _initRemote() {
    if (!mounted) return;
    final notifier = ref.read(tvRemoteReceiverProvider.notifier);
    notifier.onDanmakuUsersUpdated = _syncFromRemote;
    notifier.seedDanmakuUsers(SettingsService.to.favState.blockedDanmakuUsers);
    final remoteState = ref.read(tvRemoteReceiverProvider);
    final running = remoteState is AsyncData && (remoteState.value?.isRunning ?? false);
    if (!running) unawaited(notifier.startServer());
  }

  @override
  void dispose() {
    ref.read(tvRemoteReceiverProvider.notifier).onDanmakuUsersUpdated = null;
    super.dispose();
  }

  /// A phone push replaces the local list wholesale.
  void _syncFromRemote(List<String> users) {
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    for (var i = SettingsService.to.favState.blockedDanmakuUsers.length - 1; i >= 0; i--) {
      fav.removeBlockedDanmakuUser(i);
    }
    for (final user in users) {
      fav.addBlockedDanmakuUser(user);
    }
  }

  Future<void> _add() async {
    final added = await TvDialogUtils.show<bool>(
      context: context,
      builder: (_) => const BlockEntryAddDialog(isUser: true),
    );
    if (added == true && mounted) setState(() {});
  }

  Future<void> _showDetail(int index) async {
    final value = ref.read(favoriteRoomControllerProvider).blockedDanmakuUsers[index];
    await TvDialogUtils.show(
      context: context,
      builder: (_) => BlockEntryDetailDialog(
        title: i18nOr('blocked_users_title', '用户屏蔽'),
        value: value,
        onDelete: () => ref.read(favoriteRoomControllerProvider.notifier).removeBlockedDanmakuUser(index),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoriteRoomControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: RemoteSyncQrCard(width: 280, route: WebRemoteRouter.danmakuUsers)),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18nOr('blocked_users_title', '用户屏蔽')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(title: i18n('ui_add'), icon: Icons.add_rounded, onTap: _add),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: state.blockedDanmakuUsers.isEmpty
                    ? SizedBox(
                        height: 160.h,
                        child: AppStatusView(
                          type: AppStatusType.empty,
                          title: i18nOr('block_user_empty', '暂无屏蔽用户'),
                          subtitle: i18n('block_danmaku_user'),
                          isMini: true,
                          icon: Icons.person_off_outlined,
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 12.sp,
                          runSpacing: 12.sp,
                          children: [
                            for (var i = 0; i < state.blockedDanmakuUsers.length; i++)
                              TvButton(
                                title: state.blockedDanmakuUsers[i],
                                icon: const Icon(Icons.person_off_outlined),
                                size: TvButtonSize.small,
                                onTap: () => _showDetail(i),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
