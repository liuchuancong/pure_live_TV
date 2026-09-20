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
/// phone page sits under the list, so it stays reachable when the list is empty.
class ShieldPanel extends ConsumerStatefulWidget {
  const ShieldPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<ShieldPanel> createState() => _ShieldPanelState();
}

class _ShieldPanelState extends ConsumerState<ShieldPanel> {
  int _index = 0;

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
    final List<String> words = favState.shieldList;

    String serverUrl = '';
    if (remoteState is AsyncData) {
      final value = remoteState.value;
      if (value != null && value.isRunning) serverUrl = value.serverUrl;
    }
    final String qrData = serverUrl.isEmpty ? '' : '$serverUrl${WebRemoteRouter.danmakuFilter}';

    return PlayerIndexPanel(
      title: '${i18n('danmaku_filter')} · ${words.length}',
      rows: <PlayerPanelRow>[
        for (final String word in words)
          PlayerPanelRow(label: word, icon: Icons.block_rounded, value: i18n('delete')),
      ],
      selectedIndex: words.isEmpty ? 0 : _index.clamp(0, words.length - 1),
      emptyHint: i18nOr('empty_shield_title', i18n('ui_none')),
      onSelectionChanged: (i) => setState(() => _index = i),
      onSelect: (i) {
        if (words.isEmpty) return;
        fav.removeShieldList(i.clamp(0, words.length - 1));
      },
      onClose: widget.onClose ?? () {},
      // The phone-editing entry: caption above a compact QR — the full-width
      // 240sp code left the word list no room in a 400sp panel.
      footer: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              i18nOr('danmaku_shield_qr_hint', '手机扫码编辑屏蔽词'),
              style: AppTextStyles.t14W500.copyWith(color: context.tvTheme.secondaryTextColor),
            ),
            SizedBox(height: 8.sp),
            if (qrData.isEmpty)
              Row(
                children: [
                  SizedBox(width: 18.sp, height: 18.sp, child: tvInlineLoading(context, size: 18.sp)),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Text(
                      i18nOr('ui_remote_starting', 'Starting the phone remote service...'),
                      style: AppTextStyles.t14W500.copyWith(color: context.tvTheme.secondaryTextColor),
                    ),
                  ),
                ],
              )
            else
              TvQrCodeCard(qrData: qrData, urlText: qrData, qrSize: 150),
          ],
        ),
      ),
    );
  }
}
