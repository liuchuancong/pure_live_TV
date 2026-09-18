import 'dart:async';
import 'package:pure_live/exports/exports.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Global landing spot for live-room pushes from the phone.
///
/// The search pages bind [TvRemoteReceiver.onRoomPush] while they are on top;
/// everywhere else the callback is null and a push used to vanish. This overlay
/// binds the receiver's fallback, so a push anywhere else raises a TV dialog
/// asking whether to open the room — d-pad navigable, like every dialog here.
class GlobalRoomPushOverlay extends ConsumerStatefulWidget {
  const GlobalRoomPushOverlay({super.key});

  @override
  ConsumerState<GlobalRoomPushOverlay> createState() => _GlobalRoomPushOverlayState();
}

class _GlobalRoomPushOverlayState extends ConsumerState<GlobalRoomPushOverlay> {
  TvRemoteReceiver? _receiver;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _receiver = ref.read(tvRemoteReceiverProvider.notifier);
      _receiver?.onRoomPushFallback = _handleRoomPush;
    });
  }

  @override
  void dispose() {
    if (_receiver?.onRoomPushFallback == _handleRoomPush) {
      _receiver?.onRoomPushFallback = null;
    }
    super.dispose();
  }

  Future<void> _handleRoomPush(String input) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;
    final open = await SmartDialog.show<bool>(
      tag: 'global_room_push',
      builder: (_) => _RoomPushCard(input: input),
    );
    _dialogOpen = false;
    if (open != true || !mounted) return;
    await _openRoom(input);
  }

  /// Opens the pushed room: a link goes through the parse engine like the
  /// video-parse page does; anything else lands in room search under the first
  /// available site, which is where a bare room id or streamer name belongs.
  Future<void> _openRoom(String input) async {
    final router = ref.read(routerProvider);
    final keyword = input.trim();
    try {
      final engine = ref.read(urlParseEngineProvider);
      final result = await engine.parse(keyword);
      if (result.length >= 2) {
        final roomId = result[0];
        final platformId = result[1];
        final room = await Sites.of(platformId).liveSite.getRoomDetail(roomId: roomId, platform: platformId);
        if (mounted) LivePlayRoute(room).push(context);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    final site = Sites().availableSites(containsAll: false).first.name;
    router.push(
      AppRoutes.kSearchResult,
      extra: SearchResultArgs(keyword: keyword, site: site, searchType: kSearchTypeRoom),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _RoomPushCard extends StatelessWidget {
  const _RoomPushCard({required this.input});

  final String input;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: theme.focusColor.withValues(alpha: 0.4)),
      ),
      child: Container(
        width: 520.w,
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.live_tv_rounded, color: theme.focusColor, size: 28.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    i18nOr('room_push_title', '手机推送了一个直播间'),
                    style: AppTextStyles.t20W600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              input,
              style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 28.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TvButton(
                  title: i18n('ui_cancel'),
                  size: TvButtonSize.medium,
                  isSecondary: true,
                  onTap: () => SmartDialog.dismiss(tag: 'global_room_push'),
                ),
                SizedBox(width: 16.w),
                TvButton(
                  title: i18nOr('room_push_open', '打开直播间'),
                  size: TvButtonSize.medium,
                  autofocus: true,
                  onTap: () => SmartDialog.dismiss<bool>(tag: 'global_room_push', result: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
