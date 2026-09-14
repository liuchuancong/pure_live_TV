import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/widgets/panels/live_panel_shell.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 播放页内的「弹幕过滤」面板。
///
/// 屏蔽词与手机端扫码页面共用 [FavoriteRoomController] 的 shieldList：
/// - 电视上选中某行 = 删除该屏蔽词；
/// - 手机扫码进入网页增删后，通过 [TvRemoteReceiver.onDanmakuFilterUpdated] 回灌；
/// - 打开面板时会把当前列表播种到接收端缓存，手机页面一进去就能看到已有词。
class ShieldPanel extends ConsumerStatefulWidget {
  const ShieldPanel({super.key});

  @override
  ConsumerState<ShieldPanel> createState() => _ShieldPanelState();
}

class _ShieldPanelState extends ConsumerState<ShieldPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initRemote());
  }

  void _initRemote() {
    if (!mounted) return;
    final notifier = ref.read(tvRemoteReceiverProvider.notifier);
    notifier.onDanmakuFilterUpdated = _syncFromRemote;
    notifier.seedDanmakuFilters(SettingsService.to.favState.shieldList);
    final remoteState = ref.read(tvRemoteReceiverProvider);
    final running = remoteState is AsyncData && (remoteState.value?.isRunning ?? false);
    if (!running) unawaited(notifier.startServer());
  }

  /// 手机端推送过来的整份列表覆盖本地（两端保持一致）。
  void _syncFromRemote(List<String> filters) {
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    // 带计数上限，避免任何异常状态下死循环。
    var guard = 0;
    while (SettingsService.to.favState.shieldList.isNotEmpty && guard < 1000) {
      fav.removeShieldList(SettingsService.to.favState.shieldList.length - 1);
      guard++;
    }
    for (final word in filters) {
      fav.addShieldList(word);
    }
  }

  @override
  void dispose() {
    ref.read(tvRemoteReceiverProvider.notifier).onDanmakuFilterUpdated = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoriteRoomControllerProvider);
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final remoteState = ref.watch(tvRemoteReceiverProvider);
    final tvTheme = context.tvTheme;

    String serverUrl = '';
    if (remoteState is AsyncData) {
      final value = remoteState.value;
      if (value != null && value.isRunning) serverUrl = value.serverUrl;
    }
    final qrData = serverUrl.isEmpty ? '' : '$serverUrl${WebRemoteRouter.danmakuFilter}';
    final words = favState.shieldList;

    return LivePanelShell(
      title: i18n('danmaku_filter'),
      hint: i18nOr('ui_danmaku_filter_hint', '手机扫码增删屏蔽词；电视上选中某行可直接删除'),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.sp),
        children: [
          _buildQrEntry(context, tvTheme, qrData, words.isEmpty),
          Padding(
            padding: EdgeInsets.only(left: 16.sp, right: 16.sp, top: 8.sp, bottom: 4.sp),
            child: Text(
              '${i18n('danmaku_keyword_block')} · ${words.length}',
              style: AppTextStyles.t14W600.copyWith(color: tvTheme.secondaryTextColor),
            ),
          ),
          if (words.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              child: Text(
                i18n('ui_none'),
                style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            )
          else
            for (var i = 0; i < words.length; i++)
              LiveActionRow(
                autofocus: i == 0,
                title: words[i],
                leading: Icon(Icons.block_rounded, size: 20.sp, color: tvTheme.focusColor),
                trailing: Icon(Icons.delete_outline_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                onSelect: () => fav.removeShieldList(i),
              ),
        ],
      ),
    );
  }

  /// 二维码区域本身可聚焦，保证屏蔽词为空时遥控器仍有落点。
  Widget _buildQrEntry(BuildContext context, TvThemeData tvTheme, String qrData, bool autofocus) {
    return DpadFocusable(
      autofocus: autofocus,
      onSelect: () {},
      child: const SizedBox.shrink(),
      builder: (context, state, _) {
        final focused = state.focused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: BorderRadius.circular(12.sp),
            border: Border.all(
              color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.15),
              width: focused ? 2.sp : 1.sp,
            ),
          ),
          child: qrData.isEmpty
              ? Row(
                  children: [
                    SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: CircularProgressIndicator(strokeWidth: 2.sp, color: tvTheme.focusColor),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Text(
                        i18nOr('ui_remote_starting', '正在启动手机遥控服务...'),
                        style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                      ),
                    ),
                  ],
                )
              : TvQrCodeCard(qrData: qrData, urlText: qrData),
        );
      },
    );
  }
}
