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

/// One platform's cookie, on a page of its own.
///
/// Laid out like the movie playback page: the platform's logo and state on top,
/// then two columns — the code-scanning way in on the left, the typed way in on
/// the right — so both are visible at once and either works with a remote.
///
/// * **扫码** — for every platform with a bundled phone page: the TV starts its
///   LAN remote and shows that platform's phone page as a QR. The phone opens
///   it, pastes the cookie, and the push lands in this page's own state.
/// * **手动输入** — a multiline field for a cookie pasted with any other remote.
/// * Bilibili replaces the left column with its native device-QR sign-in (see
///   [AccountBilibiliPage]); scanning there logs the account in rather than
///   pasting a cookie.
class AccountCookiePage extends ConsumerStatefulWidget {
  const AccountCookiePage({super.key, required this.platform, this.loginPanel});

  final CookiePlatform platform;

  /// Replaces the left (scan) column entirely — Bilibili's device sign-in.
  final Widget? loginPanel;

  @override
  ConsumerState<AccountCookiePage> createState() => _AccountCookiePageState();
}

class _AccountCookiePageState extends ConsumerState<AccountCookiePage> {
  late final TextEditingController _controller;

  String _baseline = '';
  String _message = '';
  bool _dirty = false;

  /// The platform's phone page, empty until the LAN remote is up (or when this
  /// platform has no phone page at all).
  String _phoneUrl = '';
  bool _phoneStarting = false;

  @override
  void initState() {
    super.initState();
    _baseline = widget.platform.read(ref.read(cookieControllerProvider));
    _controller = TextEditingController(text: _baseline)
      ..addListener(() {
        final bool dirty = _controller.text.trim() != _baseline;
        if (dirty != _dirty) setState(() => _dirty = dirty);
      });
    // Every platform that has a phone page shows its QR — including Bilibili,
    // whose own sign-in is the left block but whose phone page still accepts a
    // pasted cookie.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPhoneBridge());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Starts the LAN remote and resolves this platform's phone page.
  Future<void> _startPhoneBridge() async {
    if (!mounted) return;
    setState(() => _phoneStarting = true);
    try {
      final String path = widget.platform.webPath ?? '';
      if (path.isEmpty) return;
      final notifier = ref.read(tvRemoteReceiverProvider.notifier);
      ServerState? server = ref.read(tvRemoteReceiverProvider).value;
      if (server?.isRunning != true) {
        await notifier.startServer();
        if (!mounted) return;
        server = ref.read(tvRemoteReceiverProvider).value;
      }
      if (!mounted) return;
      if (server?.isRunning == true) {
        setState(() => _phoneUrl = '${server!.serverUrl}$path');
      } else {
        setState(() => _message = i18n('remote_service_unavailable'));
      }
    } finally {
      if (mounted) setState(() => _phoneStarting = false);
    }
  }

  void _saveManually() {
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
    setState(() {
      _baseline = '';
      _controller.text = '';
      _dirty = false;
      _message = i18n('clear_success');
    });
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
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // The phone push is the confirmation for the scan column: a cookie written
    // from anywhere else (the phone page, another device) lands here, so the
    // editor has to adopt it instead of showing stale text.
    ref.listen(cookieControllerProvider, (previous, next) {
      if (previous == null) return;
      final String value = widget.platform.read(next);
      if (value == widget.platform.read(previous) || value == _baseline) return;
      setState(() {
        _baseline = value;
        _controller.text = value;
        _dirty = false;
        _message = value.isEmpty ? i18n('clear_success') : i18n('cookie_saved');
      });
    });

    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final String current = widget.platform.read(cookies);
    final bool configured = current.isNotEmpty;
    final theme = context.tvTheme;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      // Centred both ways with side margins: the two blocks floated apart
      // before, stretched edge to edge and stuck to the top of the page.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool bounded = constraints.maxHeight.isFinite;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 56.w, vertical: 28.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: bounded ? constraints.maxHeight : 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme, configured),
                        SizedBox(height: 32.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Flex rather than fixed widths: the pair fills the
                            // centred 1180sp box and never overflows a narrower
                            // screen.
                            Flexible(flex: 4, child: widget.loginPanel ?? _buildScanPanel(theme)),
                            SizedBox(width: 48.sp),
                            Flexible(
                              flex: 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Bilibili signs in from the left block, so its phone
                                  // bridge sits on top of the typed way in instead of
                                  // being a column of its own.
                                  if (widget.loginPanel != null) ...[_buildScanPanel(theme), SizedBox(height: 24.h)],
                                  _buildManualPanel(theme, configured, current),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_message.isNotEmpty) ...[
                          SizedBox(height: 18.h),
                          Text(_message, style: AppTextStyles.t16W500.copyWith(color: theme.focusColor)),
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

  /// Platform identity on top: its own logo, its name and the current state.
  Widget _buildHeader(TvThemeData theme, bool configured) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SiteLogo(siteId: widget.platform.siteId, size: 56),
        SizedBox(height: 12.sp),
        Text(widget.platform.name, style: AppTextStyles.t28W600.copyWith(color: theme.primaryTextColor)),
        SizedBox(height: 6.sp),
        Text(
          configured
              ? i18n(
                  'cookie_state_set',
                  args: {'count': '${widget.platform.read(ref.read(cookieControllerProvider)).length}'},
                )
              : i18n('not_set'),
          style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
        ),
      ],
    );
  }

  /// The scan block: the phone page of this platform as a QR code.
  Widget _buildScanPanel(TvThemeData theme) {
    final bool hasPhonePage = (widget.platform.webPath ?? '').isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('phone_sync_title')),
        TvSettingsCard(
          children: [
            if (!hasPhonePage)
              TvSettingsRow(
                title: i18n('set_cookie'),
                subtitle: i18n('cookie_no_phone_page'),
                icon: Icons.qr_code_2_rounded,
              )
            else if (_phoneUrl.isEmpty)
              SizedBox(
                height: 220.h,
                child: AppStatusView(
                  type: _phoneStarting ? AppStatusType.loading : AppStatusType.empty,
                  subtitle: _phoneStarting ? i18n('ui_loading') : i18n('remote_service_unavailable'),
                  isMini: true,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    TvQrCodeCard(qrData: _phoneUrl),
                    SizedBox(height: 12.h),
                    Text(
                      i18n('cookie_phone_hint'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// The right column: type or paste the cookie.
  Widget _buildManualPanel(TvThemeData theme, bool configured, String current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('cookie')),
        TvSettingsCard(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TvInputField(controller: _controller, hint: widget.platform.hint, maxLines: 5),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                i18n('cookie_tip', args: {'name': widget.platform.name}),
                style: AppTextStyles.t14W500.copyWith(color: theme.secondaryTextColor),
              ),
            ),
            TvSettingsOptionTile(
              title: i18n('save'),
              subtitle: _dirty ? i18n('unsaved_changes') : null,
              icon: Remix.save_3_line,
              options: [i18n('save')],
              index: 0,
              onChanged: (_) => _saveManually(),
            ),
            if (configured)
              TvSettingsOptionTile(
                title: i18n('clear'),
                icon: Remix.delete_bin_6_line,
                options: [i18n('clear')],
                index: 0,
                onChanged: (_) => _clear(),
              ),
          ],
        ),
      ],
    );
  }
}

/// One editable platform: its label, paste hint, current value and setter.
class CookiePlatform {
  const CookiePlatform({
    required this.siteId,
    required this.name,
    required this.hint,
    required this.read,
    required this.apply,
    this.webPath,
  });

  /// Platform id in `Sites`, resolved to the bundled logo.
  final String siteId;

  final String name;
  final String hint;
  final String Function(CookieModel) read;
  final ValueChanged<String> apply;

  /// Phone-remote page for this platform, or null when the bundled phone pages
  /// have none — the page then offers manual input only.
  final String? webPath;
}

/// The descriptor for a platform route, so the router can build the page
/// without repeating labels, store access and phone paths.
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
    webPath: site.webPath,
  );
}
