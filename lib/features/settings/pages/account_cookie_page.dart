import 'dart:async';

import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// One platform's cookie, on a page of its own.
///
/// Every platform offers both ways in, which is what the mobile app splits
/// across per-platform pages:
///
/// * **扫码** — the TV starts its LAN remote and shows a QR code for the phone
///   page of that platform. The phone opens it, pastes the cookie, and the page
///   notices the write and confirms itself. Platforms the bundled phone pages do
///   not cover say so instead of showing a dead QR code.
/// * **手动输入** — a multiline field for a cookie pasted with any other remote
///   (or a keyboard), with the same unsaved-changes guard the mobile editor has.
class AccountCookiePage extends ConsumerStatefulWidget {
  const AccountCookiePage({super.key, required this.platform, this.header, this.showPhoneBridge = true});

  final CookiePlatform platform;

  /// Extra content above the sections, used by Bilibili for its own
  /// device-QR sign-in (the phone page only carries a cookie).
  final Widget? header;

  /// Whether this platform has a phone page to scan. Bilibili replaces it with
  /// the native QR sign-in.
  final bool showPhoneBridge;

  @override
  ConsumerState<AccountCookiePage> createState() => _AccountCookiePageState();
}

class _AccountCookiePageState extends ConsumerState<AccountCookiePage> {
  late final TextEditingController _controller;

  String _baseline = '';
  String _message = '';
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _baseline = widget.platform.read(ref.read(cookieControllerProvider));
    _controller = TextEditingController(text: _baseline)
      ..addListener(() {
        final bool dirty = _controller.text.trim() != _baseline;
        if (dirty != _dirty) setState(() => _dirty = dirty);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Starts the LAN remote and returns the phone page for this platform.
  Future<String> _phoneUrl() async {
    final notifier = ref.read(tvRemoteReceiverProvider.notifier);
    ServerState? server = ref.read(tvRemoteReceiverProvider).value;
    if (server?.isRunning != true) {
      await notifier.startServer();
      if (!mounted) return '';
      server = ref.read(tvRemoteReceiverProvider).value;
    }
    final String path = widget.platform.webPath ?? '';
    if (path.isEmpty || server?.isRunning != true) return '';
    return '${server!.serverUrl}$path';
  }

  Future<void> _setUpOnPhone() async {
    setState(() => _message = i18n('ui_loading'));
    final String url = await _phoneUrl();
    if (!mounted) return;
    setState(() => _message = '');
    if (url.isEmpty) {
      setState(() => _message = i18n('remote_service_unavailable'));
      return;
    }
    // The phone push is the confirmation: no OK button to find with a remote.
    await TvDialogUtils.show<void>(
      context: context,
      builder: (dialogContext) => _PhoneCookieDialog(
        platformName: widget.platform.name,
        url: url,
        read: widget.platform.read,
      ),
    );
    if (!mounted) return;
    setState(() {
      _baseline = widget.platform.read(ref.read(cookieControllerProvider));
      _controller.text = _baseline;
      _dirty = false;
      _message = i18n('cookie_saved');
    });
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
    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final String current = widget.platform.read(cookies);
    final bool configured = current.isNotEmpty;
    final theme = context.tvTheme;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: RemoteSyncQrCard(width: 280)),
          SizedBox(height: 20.h),
          if (widget.header != null) ...[widget.header!, SizedBox(height: 16.h)],
          // 扫码
          if (widget.showPhoneBridge) ...[
            TvSettingsGroupTitle(title: i18n('qr_login')),
            TvSettingsCard(
              children: [
                TvSettingsOptionTile(
                  title: i18n('set_cookie'),
                  subtitle: widget.platform.webPath == null
                      ? i18n('cookie_no_phone_page')
                      : i18n('cookie_phone_hint'),
                  icon: Icons.qr_code_2_rounded,
                  options: [i18n('qr_login')],
                  index: 0,
                  onChanged: widget.platform.webPath == null ? null : (_) => _setUpOnPhone(),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
          // 手动输入
          TvSettingsGroupTitle(title: i18n('cookie')),
          TvSettingsCard(
            children: [
              TvSettingsRow(
                title: widget.platform.name,
                subtitle: configured
                    ? i18n('cookie_state_set', args: {'count': '${current.length}'})
                    : i18n('not_set'),
                icon: Icons.cookie_outlined,
                trailingBuilder: tvSettingsChevron,
                onSelect: () => setState(() => _message = ''),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TvInputField(
                  controller: _controller,
                  hint: widget.platform.hint,
                  maxLines: 4,
                ),
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
                icon: Remix.save_3_line,
                options: [i18n('save')],
                index: 0,
                onChanged: (_) => _saveManually(),
              ),
              TvSettingsOptionTile(
                title: i18n('clear'),
                icon: Remix.delete_bin_6_line,
                options: [i18n('clear')],
                index: 0,
                onChanged: (_) => _clear(),
              ),
            ],
          ),
          if (_message.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.sp, top: 10.sp),
              child: Text(_message, style: AppTextStyles.t16W500.copyWith(color: theme.focusColor)),
            ),
        ],
      ),
    );
  }
}

/// One editable platform: its label, paste hint, current value and setter.
class CookiePlatform {
  const CookiePlatform({
    required this.name,
    required this.hint,
    required this.read,
    required this.apply,
    this.webPath,
  });

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
    name: name,
    hint: i18n(site.hintKey, args: {'name': name}),
    read: site.read,
    apply: (value) => site.apply(SettingsService.to.cookieManager, value),
    webPath: site.webPath,
  );
}

/// "Set it up on your phone" dialog: QR code plus the address as text.
class _PhoneCookieDialog extends ConsumerStatefulWidget {
  const _PhoneCookieDialog({required this.platformName, required this.url, required this.read});

  final String platformName;
  final String url;
  final String Function(CookieModel) read;

  @override
  ConsumerState<_PhoneCookieDialog> createState() => _PhoneCookieDialogState();
}

class _PhoneCookieDialogState extends ConsumerState<_PhoneCookieDialog> {
  late String _baseline;

  @override
  void initState() {
    super.initState();
    _baseline = widget.read(ref.read(cookieControllerProvider));
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    // The phone pushes the cookie through the LAN API; that write is the signal
    // that the user is done.
    ref.listen(cookieControllerProvider, (previous, next) {
      if (previous == null) return;
      final String value = widget.read(next);
      if (value.isEmpty || value == widget.read(previous) || value == _baseline) return;
      Navigator.of(context).pop();
    });

    return TvDialog(
      title: '${i18n('set_cookie')} · ${widget.platformName}',
      cancelText: i18n('cancel'),
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n('cookie_phone_hint'), style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 20.sp)),
          SizedBox(height: 16.sp),
          Center(child: TvQrCodeCard(qrData: widget.url, urlText: widget.url)),
        ],
      ),
    );
  }
}
