import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';

class MoviePlaybackPage extends ConsumerStatefulWidget {
  const MoviePlaybackPage({super.key});

  @override
  ConsumerState<MoviePlaybackPage> createState() => _MoviePlaybackPageState();
}

class _MoviePlaybackPageState extends ConsumerState<MoviePlaybackPage> {
  static const double _pagePadding = 32;
  static const double _itemGap = 36;

  bool _isParsing = false;

  /// The URL the phone pushed last; the only input path left.
  String _lastReceivedUrl = '';
  dynamic _remoteReceiverNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remoteReceiverNotifier = ref.read(tvRemoteReceiverProvider.notifier);
      _remoteReceiverNotifier.startServer();
      _bindRemoteCallbacks();
    });
  }

  void _bindRemoteCallbacks() {
    if (_remoteReceiverNotifier == null) return;
    _remoteReceiverNotifier.onMovieReceived = (inputText) {
      _lastReceivedUrl = inputText;
      _handleParse();
    };
  }

  @override
  void dispose() {
    if (_remoteReceiverNotifier != null) {
      _remoteReceiverNotifier.onMovieReceived = null;
    }
    super.dispose();
  }

  Future<void> _handleParse() async {
    final url = _lastReceivedUrl.trim();
    if (url.isEmpty || _isParsing) return;

    setState(() => _isParsing = true);

    try {
      final engine = ref.read(urlParseEngineProvider);
      final List<String> result = await engine.parse(url);

      if (result.length >= 2) {
        final String roomId = result[0];
        final String platformId = result[1];
        final liveRoom = await Sites.of(platformId).liveSite.getRoomDetail(roomId: roomId, platform: platformId);
        if (mounted) {
          LivePlayRoute(liveRoom).push(context);
        }
      }
    } catch (_) {
      if (mounted) {
        // The app's toast, not a Material SnackBar: every other message in this
        // TV UI is a toast, and a SnackBar draws a square bar at the bottom of
        // the screen that no other page has.
        ToastUtil.show(i18n('movie_parse_failed'));
      }
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final themeColor = currentTvTheme.focusColor;
    final remoteState = ref.watch(tvRemoteReceiverProvider);

    String qrCodeAddress = i18n('ui_starting_service');
    String hintText = i18n('ui_initializing_remote_control_connection');
    bool isServerRunning = false;

    if (remoteState is AsyncData) {
      final serverState = remoteState.value!;
      isServerRunning = serverState.isRunning;
      if (serverState.isRunning) {
        qrCodeAddress = '${serverState.serverUrl}${WebRemoteRouter.movie}';
        // A human typing the address needs the origin, not the hash route —
        // the deep link travels in the QR itself.
        hintText = qrCodeAddress;
      } else if (serverState.error != null) {
        qrCodeAddress = serverState.error!;
        hintText = serverState.error!;
      }
    }

    return Column(
      children: [
        _buildHeader(currentTvTheme, isServerRunning),
        SizedBox(height: _itemGap.sp),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // The QR is the page's hero: more than half the row and no
                  // width cap, so a phone has the largest scannable target a
                  // 1080p panel can give.
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: TvQrCodeCard(qrData: qrCodeAddress, urlText: hintText),
                    ),
                  ),
                  Container(
                    width: 2.sp,
                    margin: EdgeInsets.symmetric(vertical: _pagePadding.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          currentTvTheme.primaryTextColor.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  _buildInputSection(currentTvTheme, themeColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(TvThemeData currentTvTheme, bool isServerRunning) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _pagePadding.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            i18n('movie_paste_link'),
            style: AppTextStyles.t18.copyWith(
              fontWeight: FontWeight.w500,
              color: currentTvTheme.primaryTextColor,
              height: 1,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              color: isServerRunning
                  ? currentTvTheme.focusColor.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.sp),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10.sp,
                  height: 10.sp,
                  margin: EdgeInsets.only(right: 8.sp),
                  decoration: BoxDecoration(
                    color: isServerRunning ? currentTvTheme.focusColor : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  isServerRunning ? i18n('movie_lan_started') : i18n('movie_lan_stopped'),
                  style: AppTextStyles.t20.copyWith(
                    color: isServerRunning ? currentTvTheme.focusColor : Colors.redAccent,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(TvThemeData currentTvTheme, Color themeColor) {
    return Expanded(
      flex: 6,
      child: Padding(
        padding: EdgeInsets.all(_pagePadding.sp),
        child: DpadRegion(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // What the phone pushed last, so the parse button has context.
              Text(
                _lastReceivedUrl.isEmpty ? i18n('movie_wait_phone_sync') : _lastReceivedUrl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t18.copyWith(
                  color: currentTvTheme.secondaryTextColor,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.sp),
              Row(
                children: [
                  TvButton(
                    title: _isParsing ? i18n('parsing') : i18n('start_parse'),
                    icon: Icon(Icons.rocket_launch_rounded, size: 22.sp),
                    iconPosition: TvIconPosition.left,
                    size: TvButtonSize.small,
                    onTap: _isParsing ? null : _handleParse,
                  ),
                ],
              ),
              SizedBox(height: 32.sp),
              _buildSupportInfo(currentTvTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfo(TvThemeData currentTvTheme) {
    // 22 sites as mini *buttons* filled the whole right half with chunky
    // focusable-looking controls; they are only labels, so they render as
    // quiet text chips instead, capped in height and scrollable if they ever
    // outgrow the box. `IgnorePointer` keeps them out of traversal entirely.
    // Every supported platform shows at once: compact single-line chips in a
    // free-flowing wrap, no scroll. The chips shrink (fixed 14.sp overlay
    // text, tight padding) so all ~22 fit inside the card even at the largest
    // font scale — these are labels, not content.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: currentTvTheme.cardColor,
        borderRadius: BorderRadius.circular(16.sp),
        border: Border.all(color: currentTvTheme.secondaryTextColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            i18n('movie_support_sites'),
            style: AppTextStyles.t18.copyWith(
              fontWeight: FontWeight.w500,
              color: currentTvTheme.secondaryTextColor,
              height: 1,
            ),
          ),
          SizedBox(height: 12.sp),
          IgnorePointer(
            child: Wrap(
              spacing: 8.sp,
              runSpacing: 8.sp,
              children: [
                for (final site in Sites.supportSites)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                    decoration: BoxDecoration(
                      color: currentTvTheme.backgroundColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t14.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: currentTvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
