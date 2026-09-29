import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/platforms/douyu/douyu_utils.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';

/// One platform's cookie page: the cookie itself is entered on the phone.
///
/// A remote cannot type a cookie — they run to hundreds of characters — so this
/// page is a scan target for the web remote's page for the same platform
/// (`/#/cookie/<siteId>`): the phone pastes or signs in there, and the LAN
/// bridge stores whatever arrives. What the page owns is the state of what is
/// stored, the way to renew it, and the way to clear it.
class AccountCookiePage extends ConsumerStatefulWidget {
  const AccountCookiePage({super.key, required this.platform});

  final CookiePlatform platform;

  @override
  ConsumerState<AccountCookiePage> createState() => _AccountCookiePageState();
}

class _AccountCookiePageState extends ConsumerState<AccountCookiePage> {
  /// Address of the phone page, empty until the bridge answers.
  String _phoneUrl = '';
  bool _phoneStarting = false;
  bool _renewing = false;
  String _message = '';

  late final bool _isDouyu = widget.platform.siteId == Sites.douyuSite;

  @override
  void initState() {
    super.initState();
    // Post-frame, not now: starting the bridge writes its provider (the
    // loading state), and a write during this page's first build throws
    // "Tried to modify a provider while the widget tree was building" — which
    // used to take the whole page down with it, QR included.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startPhoneBridge());
    });
  }

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
        setState(() => _message = i18n('remote_service_unavailable'));
      }
    } finally {
      if (mounted) setState(() => _phoneStarting = false);
    }
  }

  /// Drops the stored session. The Douyu renewal pair stays: it belongs to the
  /// login rather than to the cookie, and is what a later renewal needs.
  void _clear() {
    widget.platform.apply('');

    if (!mounted) return;

    setState(() {
      _message = _isDouyu ? _douyuSessionSummary('') : i18n('clear_success');
    });
  }

  // ---------------------------------------------------------------------------
  // Douyu session
  // ---------------------------------------------------------------------------

  /// Verifies the stored session by renewing it now.
  ///
  /// The renewal pair comes from the passport request and is filled in on the
  /// phone, so this button is how a viewer checks that what the phone sent
  /// actually renews — instead of finding out when a room answers as a guest.
  Future<void> _renewDouyuSession() async {
    final String cookie = ref.read(cookieControllerProvider).douyuCookie;

    if (cookie.isEmpty) {
      setState(() => _message = i18n('douyu_cookie_refresh_no_cookie'));
      return;
    }

    final ({String? longTerm, String? did}) credentials = DouyuUtils.refreshCredentials(cookie);

    if (credentials.longTerm == null || credentials.did == null) {
      setState(() => _message = i18n('douyu_cookie_refresh_no_credentials'));
      return;
    }

    if (!DouyuUtils.hasSession(cookie)) {
      setState(() => _message = i18n('douyu_cookie_refresh_no_session'));
      return;
    }

    final CookieModel cookies = ref.read(cookieControllerProvider);

    if (cookies.douyuLtp0 != credentials.longTerm || cookies.douyuDid != credentials.did) {
      ref
          .read(cookieControllerProvider.notifier)
          .setDouyuCredentials(ltp0: credentials.longTerm!, did: credentials.did!);
    }

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
      _message = renewed == null
          ? i18n('douyu_cookie_refresh_no_change')
          : i18n('douyu_cookie_refresh_ok', args: {'time': _douyuExpiryLabel(renewed)});
    });
  }

  /// Says what the stored cookie is actually worth.
  ///
  /// A cookie that is present but expired (or one that never carried a session
  /// token) looks identical to a working one in storage, and the difference only
  /// shows up later as "why is this room a guest room".
  static String _douyuSessionSummary(String cookie) {
    final String state = DouyuUtils.sessionStateName(cookie);
    final DateTime? expiry = DouyuUtils.sessionExpiry(cookie);
    final String at = expiry == null ? '' : _formatExpiry(expiry);

    return switch (state) {
      'none' => i18n('douyu_cookie_cleared'),
      'guest' => i18n('douyu_cookie_guest'),
      // The web `dy_auth` is opaque: no endpoint says when it ends, so the page
      // says that instead of a bare expiry.
      'valid' => expiry == null
          ? i18n('douyu_cookie_valid_no_expiry')
          : DouyuUtils.canRefreshSession(cookie)
          ? i18n('douyu_cookie_valid_auto_renew', args: {'time': at})
          : i18n('douyu_cookie_valid_needs_repaste', args: {'time': at}),
      'expiredRefreshable' => i18n('douyu_cookie_expired_refreshable', args: {'time': at}),
      _ => i18n('douyu_cookie_expired', args: {'time': at}),
    };
  }

  /// When the session is expected to end. Only the H5 cookie carries a deadline
  /// the app can read; a fresh web `dy_auth` is described by Douyu's seven-day
  /// rule, which is what a renewal starts over.
  static String _douyuExpiryLabel(String cookie) {
    final DateTime? expiry = DouyuUtils.sessionExpiry(cookie);
    return _formatExpiry(expiry ?? DateTime.now().add(DouyuUtils.webCookieLifetime));
  }

  static String _formatExpiry(DateTime expiry) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${expiry.year}-${two(expiry.month)}-${two(expiry.day)} ${two(expiry.hour)}:${two(expiry.minute)}';
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final String stored = widget.platform.read(cookies);
    final bool configured = _isDouyu ? DouyuUtils.hasSession(stored) : stored.isNotEmpty;

    // Centred rather than split into columns: the page has one job, and the
    // phone does it.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 660.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    padding: EdgeInsets.all(16.sp),
                    child: Center(child: TvQrCodeCard(qrData: _phoneUrl, urlText: _phoneUrl)),
                  ),
              ],
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.sp),
              child: Text(
                i18n('cookie_scan_hint', args: {'name': widget.platform.name}),
                textAlign: TextAlign.center,
                style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w300, color: theme.secondaryTextColor, height: 1.4),
              ),
            ),

            // What is stored — and only when there is something to say: an
            // "empty" state next to the QR that fills it is noise.
            if (configured) ...[
              SizedBox(height: 18.h),
              _StatusLine(
                text: _isDouyu ? _douyuSessionSummary(stored) : i18n('cookie_configured'),
                color: const Color(0xFF4CAF50),
                icon: Icons.verified_rounded,
              ),
            ],

            if (_isDouyu) ...[
              SizedBox(height: 18.h),
              TvSettingsCard(
                children: [
                  TvSettingsSwitchTile(
                    title: i18n('douyu_force_renewal'),
                    subtitle: i18n('douyu_force_renewal_hint'),
                    icon: Icons.autorenew_rounded,
                    value: cookies.douyuForceRenewal,
                    onChanged: (value) =>
                        ref.read(cookieControllerProvider.notifier).setDouyuForceRenewal(value),
                  ),
                ],
              ),
            ],

            SizedBox(height: 22.h),
            // Wrap, not Row: a translated label is as wide as the language makes
            // it, and two of them do not fit on one line in every locale.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20.sp,
              runSpacing: 12.sp,
              children: [
                if (_isDouyu)
                  TvButton(
                    title: i18n('douyu_cookie_refresh_now'),
                    size: TvButtonSize.medium,
                    isSecondary: true,
                    icon: Icon(Remix.refresh_line, size: 20.sp),
                    onTap: _renewing || !configured ? null : () => unawaited(_renewDouyuSession()),
                  ),
                TvButton(
                  title: i18n('clear'),
                  size: TvButtonSize.medium,
                  isSecondary: true,
                  icon: Icon(Remix.delete_bin_6_line, size: 20.sp),
                  onTap: configured ? _clear : null,
                ),
              ],
            ),

            if (_message.isNotEmpty) ...[
              SizedBox(height: 18.h),
              _StatusLine(text: _message, color: theme.focusColor, icon: Icons.check_circle_outline_rounded),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon + line of state: the shape both the stored-state row and the result of
/// an action take.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.sp),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(width: 8.sp),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// One platform whose cookie the app stores.
class CookiePlatform {
  const CookiePlatform({required this.siteId, required this.name, required this.read, required this.apply});

  /// Platform id in `Sites`. Also the phone page's route segment: the QR above
  /// is built as `/#/cookie/<siteId>`, so a platform whose cookie this app
  /// stores must exist as a page in web_remote (see
  /// web_remote/src/views/CookieRemote.vue).
  final String siteId;

  final String name;

  final String Function(CookieModel) read;
  final ValueChanged<String> apply;
}

/// Creates the platform descriptor for a route.
CookiePlatform cookiePlatformFor(String route) {
  final CookieSite site = AccountSettingsSectionPage.sites.firstWhere(
    (candidate) => candidate.route == route,
    orElse: () => AccountSettingsSectionPage.sites.first,
  );

  return CookiePlatform(
    siteId: site.siteId,
    name: i18n(site.titleKey),
    read: site.read,
    apply: (value) => site.apply(SettingsService.to.cookieManager, value),
  );
}
