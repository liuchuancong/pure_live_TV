import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:tv_textfield/tv_textfield.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';

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

  String _baseline = '';
  String _message = '';
  bool _dirty = false;

  /// Phone sync URL.
  String _phoneUrl = '';
  bool _phoneStarting = false;

  @override
  void initState() {
    super.initState();

    _baseline = widget.platform.read(ref.read(cookieControllerProvider));

    _controller = TextEditingController(text: _baseline)
      ..addListener(() {
        final bool dirty = _controller.text.trim() != _baseline;

        if (dirty != _dirty) {
          setState(() => _dirty = dirty);
        }
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

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cookieControllerProvider, (previous, next) {
      if (previous == null) return;

      final String value = widget.platform.read(next);

      if (value == widget.platform.read(previous) || value == _baseline) {
        return;
      }

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
                        SizedBox(height: 32.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 4,
                              child: Padding(
                                padding: EdgeInsets.only(top: widget.loginPanel == null ? 100.h : 0),
                                child: widget.loginPanel ?? _buildScanPanel(theme),
                              ),
                            ),
                            SizedBox(width: 48.sp),
                            Flexible(
                              flex: 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.loginPanel != null) ...[_buildScanPanel(theme), SizedBox(height: 24.h)],
                                  if (widget.loginPanel == null) ...[SizedBox(height: 100.h)],
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
              child: _CookieField(controller: _controller, focusNode: _fieldFocus, hint: widget.platform.hint),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
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
}

/// Cookie editor. Focus only changes visual state, not layout size.
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
      height: 230.h,
      padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 14.sp),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14.sp),
        border: Border.all(color: borderColor, width: 2.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hint,
            style: TextStyle(color: text.withValues(alpha: 0.4), fontSize: 22.sp, height: 1.4),
          ),
          SizedBox(height: 6.h),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: TvTextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                implementation: TvTextFieldImplementation.flutter,
                textAlign: TextAlign.start,
                // Outer container owns the visual frame.
                focusDecoration: const BoxDecoration(),

                minLines: null,
                maxLines: null,

                style: TextStyle(color: text, fontSize: 24.sp, height: 1.4),

                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                ),
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
    this.webPath,
  });

  /// Platform id in `Sites`.
  final String siteId;

  final String name;
  final String hint;

  final String Function(CookieModel) read;
  final ValueChanged<String> apply;

  /// Phone-remote page for this platform.
  final String? webPath;
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
    webPath: site.webPath,
  );
}
