import 'dart:async';

import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_index_panel.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Keyword shield, as an index list like the reference's shield panel.
///
/// Blocked words share [FavoriteRoomController.shieldList] with the phone scan
/// page: Up/Down pick a word, OK removes it, and words added on the phone are
/// pushed back through [TvRemoteReceiver.onDanmakuFilterUpdated]. The QR for the
/// phone page sits above the list, so it stays reachable when the list is empty.
///
/// The blocked-user list is gone with the rest of the feature: filtering danmaku
/// by author was dropped in favour of keywords, so the panel no longer offers a
/// second code for a page whose list nothing would apply.
class ShieldPanel extends ConsumerStatefulWidget {
  const ShieldPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<ShieldPanel> createState() => _ShieldPanelState();
}

class _ShieldPanelState extends ConsumerState<ShieldPanel> {
  int _index = 0;

  /// The notifier whose phone callback this panel owns.
  ///
  /// Held in a field because `ref` may not be used from `dispose`: riverpod
  /// asserts "Using ref when a widget is about to or has been unmounted is
  /// unsafe", which is exactly what the unassign used to do (the player tore
  /// the panel down on close and the error landed in the framework's
  /// finalizeTree pass).
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
    final running =
        remoteState is AsyncData && (remoteState.value?.isRunning ?? false);
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
    // Only the instance this panel registered, and without touching `ref`
    // (see [_remote]).
    _remote?.onDanmakuFilterUpdated = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoriteRoomControllerProvider);
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final remoteState = ref.watch(tvRemoteReceiverProvider);
    final List<String> words = favState.shieldList;

    String serverUrl = '';
    if (remoteState is AsyncData) {
      final value = remoteState.value;
      if (value != null && value.isRunning) serverUrl = value.serverUrl;
    }
    final String qrData = serverUrl.isEmpty
        ? ''
        : '$serverUrl${WebRemoteRouter.danmakuFilter}';

    return PlayerIndexPanel(
      title: '${i18n('danmaku_filter')} · ${words.length}',
      // No close row: Escape / the panel key close it, and Left walks back out
      // of the word list.
      showCloseRow: false,
      rows: <PlayerPanelRow>[
        for (final String word in words)
          PlayerPanelRow(
            label: word,
            icon: Icons.block_rounded,
            value: i18n('delete'),
          ),
      ],
      selectedIndex: words.isEmpty ? 0 : _index.clamp(0, words.length - 1),
      emptyHint: i18nOr('empty_shield_title', i18n('ui_none')),
      onSelectionChanged: (i) => setState(() => _index = i),
      onSelect: (i) {
        if (words.isEmpty) return;
        fav.removeShieldList(i.clamp(0, words.length - 1));
      },
      onClose: widget.onClose ?? () {},
      // The phone-editing entry at the top: the code is the first thing the
      // viewer reaches for, and a footer QR scrolled off-screen as soon as the
      // word list grew.
      header: Padding(
        padding: EdgeInsets.fromLTRB(12.sp, 4.sp, 12.sp, 8.sp),
        child: Column(
          children: [
            if (qrData.isEmpty)
              Row(
                children: [
                  SizedBox(
                    width: 18.sp,
                    height: 18.sp,
                    child: tvInlineLoading(context, size: 18.sp),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Text(
                      i18nOr(
                        'ui_remote_starting',
                        'Starting the phone remote service...',
                      ),
                      style: AppTextStyles.t14W500.copyWith(
                        color: context.tvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              // One code, one page: the phone edits the keyword list the player
              // actually applies.
              Column(
                children: [
                  Text(
                    i18n('danmaku_keyword_block'),
                    style: AppTextStyles.t14W500.copyWith(color: context.tvTheme.secondaryTextColor),
                  ),
                  SizedBox(height: 4.sp),
                  TvQrCodeCard(qrData: qrData, qrSize: 120, urlText: qrData),
                ],
              ),
              SizedBox(height: 6.sp),
              Center(
                child: Text(
                  i18nOr('danmaku_shield_qr_hint', '手机扫码编辑屏蔽词'),
                  style: AppTextStyles.t14W500.copyWith(
                    color: context.tvTheme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
