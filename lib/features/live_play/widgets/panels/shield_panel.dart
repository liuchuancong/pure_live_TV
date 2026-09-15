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

/// Danmaku filter panel shown inside the player.
///
/// Blocked words share [FavoriteRoomController] shieldList with the phone scan
/// page: selecting a row on TV deletes that word, and words added on the
/// phone are pushed back through [TvRemoteReceiver.onDanmakuFilterUpdated].
/// Opening the panel seeds the current list into the receiver cache so the
/// phone page shows existing words immediately.
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

  /// A full list pushed from the phone replaces the local one, keeping both
  /// sides identical.
  void _syncFromRemote(List<String> filters) {
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    // Bounded by a counter so no abnormal state can loop forever.
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
      hint: i18nOr(
            'ui_danmaku_filter_hint',
            'Scan the QR code on your phone to edit blocked words; on TV, select a row to remove it',
          ),
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

  /// The QR area is focusable so a remote still has a target when the list is
  /// empty.
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
                        i18nOr('ui_remote_starting', 'Starting the phone remote service...'),
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
