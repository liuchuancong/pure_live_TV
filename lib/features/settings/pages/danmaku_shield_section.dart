import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Keyword shield, in the tag page's shape: the phone QR on top, an add dialog
/// and a left-aligned chip cloud. Its own page and web route
/// ([WebRemoteRouter.danmakuFilter]).
///
/// This is the only danmaku blocklist: filtering by author was removed, so the
/// page no longer offers a user mode and the phone has no second list to edit.
class DanmakuShieldSectionPage extends ConsumerStatefulWidget {
  const DanmakuShieldSectionPage({super.key});

  @override
  ConsumerState<DanmakuShieldSectionPage> createState() => DanmakuShieldSectionPageState();
}

class DanmakuShieldSectionPageState extends ConsumerState<DanmakuShieldSectionPage> {
  /// The notifier whose phone callback this page owns; `dispose` must not touch
  /// `ref` (riverpod asserts on using it after the widget is deactivated).
  TvRemoteReceiver? _remote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initRemote());
  }

  void _initRemote() {
    if (!mounted) return;
    final notifier = ref.read(tvRemoteReceiverProvider.notifier);
    _remote = notifier;
    notifier.onDanmakuFilterUpdated = _syncFromRemote;
    notifier.seedDanmakuFilters(SettingsService.to.favState.shieldList);
    final remoteState = ref.read(tvRemoteReceiverProvider);
    final running = remoteState is AsyncData && (remoteState.value?.isRunning ?? false);
    if (!running) unawaited(notifier.startServer());
  }

  @override
  void dispose() {
    _remote?.onDanmakuFilterUpdated = null;
    super.dispose();
  }

  /// A phone push replaces the local list wholesale.
  void _syncFromRemote(List<String> keywords) {
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    for (var i = SettingsService.to.favState.shieldList.length - 1; i >= 0; i--) {
      fav.removeShieldList(i);
    }
    for (final word in keywords) {
      fav.addShieldList(word);
    }
  }

  Future<void> _add() async {
    final added = await TvDialogUtils.show<bool>(
      context: context,
      builder: (_) => const BlockEntryAddDialog(),
    );
    if (added == true && mounted) setState(() {});
  }

  Future<void> _showDetail(int index) async {
    final value = ref.read(favoriteRoomControllerProvider).shieldList[index];
    await TvDialogUtils.show(
      context: context,
      builder: (_) => BlockEntryDetailDialog(
        title: i18n('danmaku_keyword_block'),
        value: value,
        onDelete: () => ref.read(favoriteRoomControllerProvider.notifier).removeShieldList(index),
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
          const Center(child: RemoteSyncQrCard(width: 280, route: WebRemoteRouter.danmakuFilter)),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('danmaku_keyword_block')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(title: i18n('ui_add'), icon: Icons.add_rounded, onTap: _add),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: state.shieldList.isEmpty
                    ? SizedBox(
                        height: 160.h,
                        child: AppStatusView(
                          type: AppStatusType.empty,
                          title: i18nOr('block_keyword_empty', '暂无屏蔽关键词'),
                          subtitle: i18n('block_danmaku_keyword'),
                          isMini: true,
                          icon: Icons.filter_alt_outlined,
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 12.sp,
                          runSpacing: 12.sp,
                          children: [
                            for (var i = 0; i < state.shieldList.length; i++)
                              TvButton(
                                title: state.shieldList[i],
                                icon: const Icon(Icons.filter_alt_outlined),
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

/// Add dialog, in the tag page's shape: one required input, validated in
/// place — empty and duplicates keep the dialog open with an error line.
class BlockEntryAddDialog extends ConsumerStatefulWidget {
  const BlockEntryAddDialog({super.key});

  @override
  ConsumerState<BlockEntryAddDialog> createState() => _BlockEntryAddDialogState();
}

class _BlockEntryAddDialogState extends ConsumerState<BlockEntryAddDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      // A dialog exists to be typed into: the field goes straight into editing
      // via its own Select handler, like the tag add dialog.
      _focusNode.onKeyEvent?.call(
        _focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.select,
          logicalKey: LogicalKeyboardKey.select,
          timeStamp: Duration.zero,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = i18nOr('block_entry_empty', '内容不能为空'));
      return;
    }
    final container = ProviderScope.containerOf(context);
    final state = container.read(favoriteRoomControllerProvider);
    final list = state.shieldList;
    if (list.any((e) => e.trim().toLowerCase() == value.toLowerCase())) {
      setState(() => _error = i18nOr('block_entry_duplicate', '该条目已存在'));
      return;
    }
    final fav = container.read(favoriteRoomControllerProvider.notifier);
    final ok = fav.addShieldList(value);
    if (!ok) {
      setState(() => _error = i18nOr('block_entry_invalid', '条目无效'));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: i18nOr('block_add_keyword', '添加屏蔽关键词'),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: _submit,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvInputField(
              controller: _controller,
              focusNode: _focusNode,
              hint: i18n('block_danmaku_keyword'),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10.sp),
                child: Text(_error, style: TextStyle(fontSize: 14.sp, color: context.tvTheme.focusColor)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Entry detail: the value and deletion behind the confirm button.
class BlockEntryDetailDialog extends StatelessWidget {
  const BlockEntryDetailDialog({super.key, required this.title, required this.value, required this.onDelete});

  final String title;
  final String value;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: title,
      confirmText: i18n('delete'),
      cancelText: i18n('cancel'),
      onConfirm: onDelete,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.t26W600),
            SizedBox(height: 16.sp),
            Text(
              i18nOr('block_delete_confirm', '确定要删除这条屏蔽项吗？'),
              style: TextStyle(fontSize: 15.sp, color: context.tvTheme.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
