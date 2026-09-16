import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';

class MoviePlaybackPage extends ConsumerStatefulWidget {
  const MoviePlaybackPage({super.key});

  @override
  ConsumerState<MoviePlaybackPage> createState() => _MoviePlaybackPageState();
}

class _MoviePlaybackPageState extends ConsumerState<MoviePlaybackPage> {
  static const double _pagePadding = 32;
  static const double _centerWidgetWidth = 520;
  static const double _itemGap = 36;

  final TextEditingController _urlController = TextEditingController();
  bool _isInputFieldFocused = false;
  bool _isParsing = false;
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
      _urlController.text = inputText;
      _handleParse();
    };
  }

  @override
  void dispose() {
    if (_remoteReceiverNotifier != null) {
      _remoteReceiverNotifier.onMovieReceived = null;
    }
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleParse() async {
    final url = _urlController.text.trim();
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
          context.push(AppRoutes.kLivePlay, extra: liveRoom);
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
        hintText = '${serverState.serverUrl}${WebRemoteRouter.movie}';
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
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SizedBox(
                        width: _centerWidgetWidth.sp,
                        child: TvQrCodeCard(qrData: qrCodeAddress, urlText: hintText),
                      ),
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
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              color: isServerRunning
                  ? currentTvTheme.focusColor.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.sp),
            ),
            child: Text(
              isServerRunning ? i18n('movie_lan_started') : i18n('movie_lan_stopped'),
              style: TextStyle(
                color: isServerRunning ? currentTvTheme.focusColor : Colors.redAccent,
                fontSize: 20.sp,
                height: 1,
              ),
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
              Text(
                i18n('movie_paste_link'),
                style: AppTextStyles.t18W500.copyWith(
                  fontSize: 28.sp,
                  color: currentTvTheme.secondaryTextColor,
                  height: 1,
                ),
              ),
              SizedBox(height: _itemGap.sp),
              TvInputField(
                controller: _urlController,
                hint: i18n('movie_wait_phone_sync'),
                height: 72.sp,
                maxLines: 1,
                onSubmitted: (url) => _handleParse,
                postFixWidget: GestureDetector(
                  onTap: _handleParse,
                  child: Padding(
                    padding: EdgeInsets.only(right: 6.sp),
                    child: Icon(Icons.search_rounded, color: themeColor, size: 32.sp),
                  ),
                ),
                builder: (content) {
                  return Focus(
                    onFocusChange: (hasFocus) {
                      setState(() {
                        _isInputFieldFocused = hasFocus;
                      });
                    },
                    child: AnimatedScale(
                      scale: _isInputFieldFocused ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        height: 80.sp,
                        padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 12.sp),
                        decoration: BoxDecoration(
                          color: currentTvTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(32.sp),
                          border: Border.all(color: themeColor, width: _isInputFieldFocused ? 2.5.sp : 1.5.sp),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: _isInputFieldFocused ? 0.5 : 0.35),
                              blurRadius: 12.sp,
                            ),
                          ],
                        ),
                        child: content,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 40.sp),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200.sp,
                    child: TvButton(
                      title: _isParsing ? i18n('parsing') : i18n('start_parse'),
                      icon: Icon(Icons.rocket_launch_rounded, size: 28.sp),
                      iconPosition: TvIconPosition.left,
                      size: TvButtonSize.medium,
                      onTap: _handleParse,
                    ),
                  ),
                  SizedBox(width: 24.sp),
                  SizedBox(
                    width: 150.sp,
                    child: TvButton(
                      title: i18n('clear'),
                      icon: Icon(Icons.cleaning_services_rounded, size: 28.sp),
                      iconPosition: TvIconPosition.left,
                      size: TvButtonSize.medium,
                      isSecondary: true,
                      onTap: () => _urlController.clear(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 48.sp),
              _buildSupportInfo(currentTvTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfo(TvThemeData currentTvTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: currentTvTheme.cardColor,
        borderRadius: BorderRadius.circular(16.sp),
        border: Border.all(color: currentTvTheme.focusedCardColor.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.sp,
        runSpacing: 8.sp,
        children: Sites.supportSites
            .map((site) => site.name)
            .map(
              (e) => Text(
                e,
                style: AppTextStyles.t18W600.copyWith(
                  color: currentTvTheme.primaryTextColor.withValues(alpha: 0.75),
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
