import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/platforms/douyu/douyu_utils.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:url_launcher/url_launcher.dart';

/// One platform's cookie page.
class AccountCookiePage extends ConsumerStatefulWidget {
  const AccountCookiePage({super.key, required this.platform, this.loginPanel});

  final CookiePlatform platform;

  /// Replaces the scan column, used by Bilibili native QR login.
  final Widget? loginPanel;

  @override
  ConsumerState<AccountCookiePage> createState() => _AccountCookiePageState();
}

class _AccountCookiePageState extends ConsumerState<AccountCookiePage> {
  late final TextEditingController _controller;
  late final FocusNode _fieldFocus;

  /// Douyu only: the renewal pair is not part of the page cookie, so it needs
  /// inputs of its own.
  late final bool _isDouyu;
  TextEditingController? _ltp0Controller;
  TextEditingController? _didController;
  FocusNode? _ltp0Focus;
  FocusNode? _didFocus;
  String _ltp0Baseline = '';
  String _didBaseline = '';
  bool _renewing = false;

  String _baseline = '';
  String _message = '';
  bool _dirty = false;

  /// Phone sync URL.
  String _phoneUrl = '';
  bool _phoneStarting = false;

  @override
  void initState() {
    super.initState();

    final CookieModel cookies = ref.read(cookieControllerProvider);

    _baseline = widget.platform.read(cookies);
    _isDouyu = widget.platform.siteId == Sites.douyuSite;

    _controller = TextEditingController(text: _baseline)
      ..addListener(() {
        if (_isDouyu) _absorbPastedCredentials();

        _updateDirty();
      });

    _fieldFocus = FocusNode(debugLabel: 'CookieField');

    if (_isDouyu) {
      _ltp0Baseline = cookies.douyuLtp0;
      _didBaseline = cookies.douyuDid;
      _ltp0Controller = TextEditingController(text: _ltp0Baseline)..addListener(_updateDirty);
      _didController = TextEditingController(text: _didBaseline)..addListener(_updateDirty);
      _ltp0Focus = FocusNode(debugLabel: 'DouyuLtp0');
      _didFocus = FocusNode(debugLabel: 'DouyuDid');
      // A cookie pasted from the passport request already carries the renewal
      // key and the device id; filling the fields from it saves the viewer from
      // hunting through the same string by hand.
      _absorbPastedCredentials();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _startPhoneBridge());
  }

  @override
  void dispose() {
    _fieldFocus.dispose();
    _ltp0Focus?.dispose();
    _didFocus?.dispose();
    _controller.dispose();
    _ltp0Controller?.dispose();
    _didController?.dispose();
    super.dispose();
  }

  void _updateDirty() {
    final bool dirty =
        _controller.text.trim() != _baseline ||
        (_ltp0Controller != null && _ltp0Controller!.text.trim() != _ltp0Baseline) ||
        (_didController != null && _didController!.text.trim() != _didBaseline);

    if (dirty != _dirty && mounted) {
      setState(() => _dirty = dirty);
    }
  }

  /// Starts the LAN remote and creates the phone cookie URL.
  Future<void> _startPhoneBridge() async {
    if (!mounted) return;

    setState(() => _phoneStarting = true);

    try {
      final notifier = ref.read(tvRemoteReceiverProvider.notifier);

      ServerState? server = ref.read(tvRemoteReceiverProvider).value;

      if (server?.isRunning != true) {
        await notifier.startServer();

        if (!mounted) return;

        server = ref.read(tvRemoteReceiverProvider).value;
      }

      if (!mounted) return;

      if (server?.isRunning == true) {
        setState(() {
          // The page is addressed by platform id, so web_remote must have a
          // route per id this app stores a cookie for — a missing one silently
          // lands the phone on the dashboard. Both lists live in
          // web_remote/src/views/CookieRemote.vue and router.js.
          _phoneUrl = '${server!.serverUrl}/#/cookie/${widget.platform.siteId}';
        });
      } else {
        setState(() {
          _message = i18n('remote_service_unavailable');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _phoneStarting = false);
      }
    }
  }

  void _saveManually() {
    if (_isDouyu) {
      _saveDouyu();
      return;
    }

    final String value = _controller.text.trim();

    widget.platform.apply(value);

    if (!mounted) return;

    setState(() {
      _baseline = value;
      _dirty = false;
      _message = i18n('cookie_saved_local');
    });
  }

  void _clear() {
    widget.platform.apply('');

    if (!mounted) return;

    // Douyu keeps the renewal pair: it belongs to the login, not to the cookie,
    // and is what lets a later paste renew itself. Only the session goes.
    if (_isDouyu) {
      ref.read(cookieControllerProvider.notifier).setDouyuCookieSavedAt(0);
    }

    setState(() {
      _baseline = '';
      _controller.text = '';
      _dirty = false;
      _message = _isDouyu ? _douyuSessionSummary('') : i18n('clear_success');
    });
  }

  // ---------------------------------------------------------------------------
  // Douyu session
  // ---------------------------------------------------------------------------

  /// Copies `LTP0` / `dy_did` out of whatever was pasted into the cookie box.
  ///
  /// Only fills what it actually finds, and never clears a field: a page cookie
  /// legitimately has neither, and wiping a value the viewer typed earlier would
  /// silently disable the renewal.
  void _absorbPastedCredentials() {
    final String pasted = _controller.text;
    if (pasted.trim().isEmpty) return;

    final String? ltp0 = _douyuField(pasted, DouyuUtils.longTermTokenName);
    if (ltp0 != null && ltp0 != _ltp0Controller!.text) {
      _ltp0Controller!.text = ltp0;
    }

    final String? did = _douyuField(pasted, DouyuUtils.deviceIdName);
    if (did != null && did != _didController!.text) {
      _didController!.text = did;
    }
  }

  /// Reads one field, tolerating a whole `Cookie: a=b; c=d` header line.
  static String? _douyuField(String cookie, String name) {
    final String header = cookie.replaceFirst(RegExp(r'^\s*Cookie:\s*', caseSensitive: false), '');
    final String? value = DouyuUtils.cookieField(header, name)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  void _saveDouyu() {
    final CookieController cookies = ref.read(cookieControllerProvider.notifier);
    final String pasted = normalizeAccountCookie(_controller.text);
    final String stored = ref.read(cookieControllerProvider).douyuCookie;
    final String ltp0 = _ltp0Controller!.text.trim();
    final String did = _didController!.text.trim();

    // The box accepts either cookie and they are not interchangeable: the page
    // cookie carries the login (`dy_auth`) while the passport cookie carries the
    // ability to renew it. So a passport paste only contributes the renewal
    // pair, and a paste with no session never replaces a stored login.
    if (DouyuUtils.isCredentialOnly(pasted)) {
      cookies.setDouyuCredentials(ltp0: ltp0, did: did);
      if (!DouyuUtils.hasSession(stored)) cookies.setDouyuCookie('');

      setState(() {
        _baseline = ref.read(cookieControllerProvider).douyuCookie;
        _ltp0Baseline = ltp0;
        _didBaseline = did;
        _dirty = false;
        _message = i18n('douyu_cookie_credentials_only');
      });
      return;
    }

    final String effective = DouyuUtils.resolveStoredCookie(pasted, stored);
    final bool absorbed = !DouyuUtils.hasSession(pasted) && effective == stored && stored.isNotEmpty;

    cookies.setDouyuCookie(effective);
    cookies.setDouyuCredentials(ltp0: ltp0, did: did);
    // douyu.com issues `dy_auth` for seven days and the header the viewer pasted
    // does not carry that deadline: recording the moment is the only way to know
    // when to renew it.
    cookies.setDouyuCookieSavedAt(effective.isEmpty ? 0 : DateTime.now().millisecondsSinceEpoch ~/ 1000);

    setState(() {
      _baseline = effective;
      _ltp0Baseline = ltp0;
      _didBaseline = did;
      _dirty = false;

      if (_controller.text != effective) {
        _controller.text = effective;
      }

      _message = absorbed ? i18n('douyu_cookie_credentials_absorbed') : _douyuSessionSummary(effective);
    });
  }

  /// Renews the cookie with the long-term key, right now.
  ///
  /// Playback renews on its own inside the seven-day window; this exists so the
  /// viewer can check that the pasted LTP0 and dy_did actually work instead of
  /// waiting up to a week to find out.
  Future<void> _renewDouyuSession() async {
    final String cookie = normalizeAccountCookie(_controller.text);

    if (cookie.isEmpty) {
      setState(() => _message = i18n('douyu_cookie_refresh_no_cookie'));
      return;
    }

    final ({String? longTerm, String? did}) credentials = DouyuUtils.refreshCredentials(
      cookie,
      longTerm: _ltp0Controller!.text,
      did: _didController!.text,
    );

    if (credentials.longTerm == null || credentials.did == null) {
      setState(() => _message = i18n('douyu_cookie_refresh_no_credentials'));
      return;
    }

    if (DouyuUtils.sessionToken(cookie) == null) {
      setState(() => _message = i18n('douyu_cookie_refresh_no_session'));
      return;
    }

    // What was typed is what the viewer means by "use these values": store the
    // pair before the renewal reads it back.
    ref
        .read(cookieControllerProvider.notifier)
        .setDouyuCredentials(ltp0: credentials.longTerm!, did: credentials.did!);

    setState(() => _renewing = true);

    final String? renewed = await DouyuUtils.refreshSession(
      accountCookie: cookie,
      longTerm: credentials.longTerm,
      did: credentials.did,
      force: true,
    );

    if (!mounted) return;

    setState(() {
      _renewing = false;

      if (renewed == null) {
        _message = i18n('douyu_cookie_refresh_no_change');
        return;
      }

      _baseline = renewed;
      _ltp0Baseline = credentials.longTerm!;
      _didBaseline = credentials.did!;
      _dirty = false;

      if (_controller.text != renewed) {
        _controller.text = renewed;
      }

      _message = i18n('douyu_cookie_refresh_ok', args: {'time': _douyuExpiryLabel()});
    });
  }

  /// Says what the stored cookie is actually worth.
  ///
  /// A cookie that is present but expired (or one that never carried a session
  /// token) looks identical to a working one in the editor, and the difference
  /// only shows up later as "why is this room a guest room".
  static String _douyuSessionSummary(String cookie) {
    final DouyuSessionState state = DouyuUtils.sessionState(cookie);
    final DateTime? expiry = DouyuUtils.sessionExpiry(cookie);
    final String at = expiry == null ? '' : _formatExpiry(expiry);

    return switch (state) {
      DouyuSessionState.none => i18n('douyu_cookie_cleared'),
      DouyuSessionState.guest => i18n('douyu_cookie_guest'),
      // The web cookie's token is opaque: its end comes from the recorded save
      // time and Douyu's seven-day rule, so say that instead of a bare expiry.
      DouyuSessionState.valid => expiry == null
          ? i18n('douyu_cookie_valid_no_expiry')
          : DouyuUtils.canRefreshSession(cookie)
          ? i18n('douyu_cookie_valid_auto_renew', args: {'time': at})
          : i18n('douyu_cookie_valid_needs_repaste', args: {'time': at}),
      DouyuSessionState.expiredRefreshable => i18n('douyu_cookie_expired_refreshable', args: {'time': at}),
      DouyuSessionState.expired => i18n('douyu_cookie_expired', args: {'time': at}),
    };
  }

  /// When the session is expected to end. The web `dy_auth` is opaque, so its
  /// end is the recorded save time plus Douyu's seven-day rule.
  static String _douyuExpiryLabel() {
    final DateTime savedAt = DouyuUtils.storedSessionSavedAt() ?? DateTime.now();
    return _formatExpiry(savedAt.add(DouyuUtils.webCookieLifetime));
  }

  static String _formatExpiry(DateTime expiry) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${expiry.year}-${two(expiry.month)}-${two(expiry.day)} ${two(expiry.hour)}:${two(expiry.minute)}';
  }

  Future<void> _openPassport() async {
    try {
      await launchUrl(Uri.parse('https://passport.douyu.com/'), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser on this device: the address is on screen and can be typed on
      // a PC instead.
    }
  }

  Future<void> _confirmLeave() async {
    final bool? discard = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('discard_cookie_changes'),
      message: i18n('discard_cookie_changes_detail'),
      confirmText: i18n('discard'),
      cancelText: i18n('keep_editing'),
    );

    if (discard != true || !mounted) return;

    setState(() => _dirty = false);

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cookieControllerProvider, (previous, next) {
      if (previous == null) return;

      final String value = widget.platform.read(next);

      if (value != widget.platform.read(previous) && value != _baseline) {
        setState(() {
          _baseline = value;
          _controller.text = value;
          _dirty = false;
          _message = _isDouyu
              ? _douyuSessionSummary(value)
              : (value.isEmpty ? i18n('clear_success') : i18n('cookie_saved'));
        });
      }

      // The renewal pair can arrive on its own (the phone's page stores the two
      // fields without touching the login cookie), so keep them in sync here or
      // the page would show values that are no longer stored.
      if (_isDouyu && (next.douyuLtp0 != _ltp0Baseline || next.douyuDid != _didBaseline)) {
        _ltp0Baseline = next.douyuLtp0;
        _didBaseline = next.douyuDid;
        _ltp0Controller!.text = next.douyuLtp0;
        _didController!.text = next.douyuDid;
      }
    });

    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final String current = widget.platform.read(cookies);
    // A stored cookie is not the same as a working login: an expired one is a
    // guest request whatever its length, so the badge follows the session the
    // cookie actually carries. One that is expired but carries the renewal key
    // stays "configured", because playback renews it on its own.
    final DouyuSessionState? douyuSession = _isDouyu ? DouyuUtils.sessionState(current) : null;
    final bool configured = douyuSession == null
        ? current.isNotEmpty
        : (douyuSession == DouyuSessionState.valid || douyuSession == DouyuSessionState.expiredRefreshable);
    final theme = context.tvTheme;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_confirmLeave());
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool bounded = constraints.maxHeight.isFinite;
          final double fillHeight = bounded ? constraints.maxHeight : 0;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: fillHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 56.w, vertical: 28.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: fillHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Platform title and configured badge.
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.platform.name,
                                style: AppTextStyles.t28W600.copyWith(color: theme.primaryTextColor),
                              ),
                            ),
                            _CookieStatusBadge(configured: configured),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        // No IntrinsicHeight here: the panels contain
                        // LayoutBuilders (settings rows, QR card), and
                        // measuring intrinsic dimensions through one is
                        // unsupported and throws. The columns size naturally.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 4,
                              child: widget.loginPanel ?? _buildScanPanel(theme),
                            ),
                            SizedBox(width: 48.sp),
                            Flexible(
                              flex: 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.loginPanel != null) ...[_buildScanPanel(theme), SizedBox(height: 24.h)],
                                  _buildManualPanel(theme, configured),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_message.isNotEmpty) ...[
                          SizedBox(height: 18.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 20.sp, color: theme.focusColor),
                              SizedBox(width: 8.sp),
                              Text(_message, style: AppTextStyles.t16W500.copyWith(color: theme.focusColor)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Phone sync QR code.
  Widget _buildScanPanel(TvThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('phone_sync_title')),

        TvSettingsCard(
          children: [
            if (_phoneUrl.isEmpty)
              SizedBox(
                height: 220.h,
                child: AppStatusView(
                  type: _phoneStarting ? AppStatusType.loading : AppStatusType.empty,
                  subtitle: _phoneStarting ? i18n('ui_loading') : i18n('remote_service_unavailable'),
                  isMini: true,
                  icon: Remix.smartphone_line,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TvQrCodeCard(qrData: _phoneUrl, urlText: _phoneUrl),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Manual cookie input.
  Widget _buildManualPanel(TvThemeData theme, bool configured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('cookie')),
        TvSettingsCard(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
              child: _CookieField(
                controller: _controller,
                focusNode: _fieldFocus,
                hint: widget.platform.hint,
                height: _isDouyu ? 200 : 230,
              ),
            ),
            if (_isDouyu) ...<Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
                child: _CookieField(
                  controller: _ltp0Controller!,
                  focusNode: _ltp0Focus!,
                  label: i18n('douyu_ltp0_label'),
                  hint: i18n('douyu_ltp0_hint'),
                  height: 120,
                  maxLines: 1,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
                child: _CookieField(
                  controller: _didController!,
                  focusNode: _didFocus!,
                  label: i18n('douyu_did_label'),
                  hint: i18n('douyu_did_hint'),
                  height: 120,
                  maxLines: 1,
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: _isDouyu
                        ? _buildDouyuTip(theme)
                        : Text(
                            i18n('cookie_tip', args: {'name': widget.platform.name}),
                            style: AppTextStyles.t18W500.copyWith(color: theme.secondaryTextColor),
                          ),
                  ),
                  SizedBox(width: 12.sp),
                  Text(
                    '${_controller.text.length}',
                    style: AppTextStyles.t18W500.copyWith(color: theme.secondaryTextColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TvButton(
                      title: i18n('save'),
                      size: TvButtonSize.medium,
                      icon: Icon(Remix.save_3_line, size: 20.sp),
                      onTap: _dirty ? _saveManually : null,
                    ),
                    if (_isDouyu) ...<Widget>[
                      SizedBox(width: 20.sp),
                      TvButton(
                        title: i18n('douyu_cookie_refresh_now'),
                        size: TvButtonSize.medium,
                        isSecondary: true,
                        icon: Icon(Remix.refresh_line, size: 20.sp),
                        onTap: _renewing ? null : () => unawaited(_renewDouyuSession()),
                      ),
                    ],
                    SizedBox(width: 20.sp),
                    TvButton(
                      title: i18n('clear'),
                      size: TvButtonSize.medium,
                      isSecondary: true,
                      icon: Icon(Remix.delete_bin_6_line, size: 20.sp),
                      onTap: _clear,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 6.h),
          ],
        ),
      ],
    );
  }

  /// Where the renewal key and the device id are found.
  ///
  /// The reference makes the passport address tappable; a TV has no pointer, so
  /// the address is a row a remote can reach instead.
  Widget _buildDouyuTip(TvThemeData theme) {
    final TextStyle body = AppTextStyles.t18W500.copyWith(color: theme.secondaryTextColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(i18n('douyu_cookie_tip_step1'), style: body),
        SizedBox(height: 10.h),
        Text(i18n('douyu_cookie_tip_step2'), style: body),
        SizedBox(height: 12.h),
        TvButton(
          title: 'passport.douyu.com',
          size: TvButtonSize.small,
          isSecondary: true,
          icon: Icon(Icons.open_in_new_rounded, size: 18.sp),
          onTap: () => unawaited(_openPassport()),
        ),
        SizedBox(height: 12.h),
        Text(i18n('douyu_cookie_tip_lifetime'), style: body),
      ],
    );
  }
}

/// Cookie editor. Focus only changes visual state, not layout size.
class _CookieField extends StatefulWidget {
  const _CookieField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.label,
    this.height = 230,
    this.maxLines,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  /// Field name. Shown above the hint, for the two Douyu inputs whose hint is a
  /// whole sentence rather than an example.
  final String? label;

  final double height;
  final int? maxLines;

  @override
  State<_CookieField> createState() => _CookieFieldState();
}

class _CookieFieldState extends State<_CookieField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    final bool focused = widget.focusNode.hasFocus;

    if (focused != _focused && mounted) {
      setState(() => _focused = focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    final Color fill = _focused ? theme.focusedCardColor : theme.backgroundColor;

    final Color text = TvThemeData.readableOn(fill);

    final Color borderColor = _focused ? theme.focusColor : theme.secondaryTextColor.withValues(alpha: 0.25);

    return Container(
      height: widget.height.h,
      padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 14.sp),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14.sp),
        border: Border.all(color: borderColor, width: 2.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(color: text.withValues(alpha: 0.85), fontSize: 22.sp, fontWeight: FontWeight.w600),
            ),
          Text(
            widget.hint,
            style: TextStyle(color: text.withValues(alpha: 0.4), fontSize: 22.sp, height: 1.4),
          ),
          SizedBox(height: 6.h),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              // The outer container owns the frame (builder: true), so this
              // field is bare text over it, unbounded and scroll-free.
              child: TvInputField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textAlign: TextAlign.start,
                minLines: 1,
                maxLines: widget.maxLines,
                textColor: text,
                builder: (content, _) => content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One editable platform.
class CookiePlatform {
  const CookiePlatform({
    required this.siteId,
    required this.name,
    required this.hint,
    required this.read,
    required this.apply,
  });

  /// Platform id in `Sites`. Also the phone page's route segment: the pairing
  /// QR below is built as `/#/cookie/<siteId>`, so a platform whose cookie this
  /// app stores must exist as a page in web_remote (see
  /// web_remote/src/views/CookieRemote.vue).
  final String siteId;

  final String name;
  final String hint;

  final String Function(CookieModel) read;
  final ValueChanged<String> apply;
}

/// Creates the platform descriptor for a route.
CookiePlatform cookiePlatformFor(String route) {
  final CookieSite site = AccountSettingsSectionPage.sites.firstWhere(
    (candidate) => candidate.route == route,
    orElse: () => AccountSettingsSectionPage.sites.first,
  );

  final String name = i18n(site.titleKey);

  return CookiePlatform(
    siteId: site.siteId,
    name: name,
    hint: i18n(site.hintKey, args: {'name': name}),
    read: site.read,
    apply: (value) => site.apply(SettingsService.to.cookieManager, value),
  );
}

/// Configured badge: green when a cookie is stored, grey otherwise.
class _CookieStatusBadge extends StatelessWidget {
  const _CookieStatusBadge({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final Color color = configured ? const Color(0xFF4CAF50) : theme.secondaryTextColor;
    final String label = configured
        ? i18nOr('cookie_configured', 'Configured')
        : i18nOr('cookie_not_configured', 'Not configured');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.sp),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            configured ? Icons.verified_rounded : Icons.info_outline_rounded,
            size: 16.sp,
            color: color,
          ),
          SizedBox(width: 6.sp),
          Text(label, style: AppTextStyles.t16W500.copyWith(color: color)),
        ],
      ),
    );
  }
}
