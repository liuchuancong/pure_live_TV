import 'dart:async';

import 'package:tv_textfield/tv_textfield.dart';
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
/// * **扫码** — every platform has a phone page now: the bundled web remote has
///   a per-platform cookie route (`/#/cookie/<site>`), so the QR opens it on the
///   phone, the cookie is pasted there, and the push lands in this page's own
///   state. Bilibili's left column is its native device-QR sign-in instead (see
///   [AccountBilibiliPage]).
/// * **手动输入** — a multiline field for a cookie pasted with any other remote.
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
  late final FocusNode _fieldFocus;

  String _baseline = '';
  String _message = '';
  bool _dirty = false;

  /// The platform's phone page, empty until the LAN remote is up.
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
    _fieldFocus = FocusNode(debugLabel: 'CookieField');
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPhoneBridge());
  }

  @override
  void dispose() {
    _fieldFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Starts the LAN remote and resolves this platform's phone page.
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
        // The web remote's per-platform cookie route: it exists for every
        // platform the app carries a cookie for, so no site is left without a
        // phone-side way in.
        setState(() => _phoneUrl = '${server!.serverUrl}/#/cookie/${widget.platform.siteId}');
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
          // The settings shell wraps this page in a scroll view, so the incoming
          // height is *infinite*: only a bounded viewport may be asked to fill it
          // (an infinite minHeight is a hard layout assertion).
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
                                  _buildManualPanel(theme, configured),
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 4.sp),
          decoration: BoxDecoration(
            color: (configured ? theme.focusColor : theme.secondaryTextColor).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999.sp),
          ),
          child: Text(
            configured
                ? i18n(
                    'cookie_state_set',
                    args: {'count': '${widget.platform.read(ref.read(cookieControllerProvider)).length}'},
                  )
                : i18n('not_set'),
            style: AppTextStyles.t14W500.copyWith(color: configured ? theme.focusColor : theme.secondaryTextColor),
          ),
        ),
      ],
    );
  }

  /// The scan block: the phone page of this platform as a QR code.
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

  /// The right column: type or paste the cookie, then save or clear.
  Widget _buildManualPanel(TvThemeData theme, bool configured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('cookie')),
        TvSettingsCard(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
              child: _CookieField(
                controller: _controller,
                focusNode: _fieldFocus,
                hint: widget.platform.hint,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i18n('cookie_tip', args: {'name': widget.platform.name}),
                      style: AppTextStyles.t14W500.copyWith(color: theme.secondaryTextColor),
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Text(
                    '${_controller.text.length}',
                    style: AppTextStyles.t14W500.copyWith(color: theme.secondaryTextColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            // 保存 / 清空 as real buttons, centred under the field: the rows
            // they replaced read as settings entries, not as the actions of the
            // text above them.
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvButton(
                    title: i18n('save'),
                    size: TvButtonSize.medium,
                    icon: Icon(Remix.save_3_line, size: 20.sp),
                    onTap: _dirty ? _saveManually : null,
                  ),
                  SizedBox(width: 20.sp),
                  if (configured)
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
            SizedBox(height: 6.h),
          ],
        ),
      ],
    );
  }
}

/// The cookie editor: [TvTextField] (flutter backend) inside one single frame.
///
/// The field it replaces stacked an app frame around a filled [InputDecorator]
/// around another container — three boxes with their own edges, which read as a
/// doubled ("ghosted") field on TV. Here the package's decoration is fully
/// transparent (no border, no fill) and the one [AnimatedContainer] owns the
/// background, the radius and the focus ring, so exactly one box is drawn.
class _CookieField extends StatefulWidget {
  const _CookieField({required this.controller, required this.focusNode, required this.hint});

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

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
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final Color fill = _focused ? theme.focusedCardColor : theme.backgroundColor;
    final Color text = TvThemeData.readableOn(fill);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 14.sp),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14.sp),
        border: Border.all(color: _focused ? theme.focusColor : theme.secondaryTextColor.withValues(alpha: 0.25), width: 2.sp),
      ),
      child: TvTextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        implementation: TvTextFieldImplementation.flutter,
        // The frame above is the only decoration; anything the package draws
        // here would be the second, "ghost" one.
        focusDecoration: const BoxDecoration(),
        minLines: 4,
        maxLines: 6,
        style: TextStyle(color: text, fontSize: 24.sp, height: 1.4),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: text.withValues(alpha: 0.4), fontSize: 22.sp),
          isDense: true,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
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

  /// Phone-remote page for this platform. Kept for the router's descriptor;
  /// the page itself builds the per-platform phone route from [siteId].
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
