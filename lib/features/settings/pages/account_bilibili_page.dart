import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/account_cookie_page.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Bilibili: the account page, so it has more than the other platforms.
///
/// 扫码登录 is the app's own device-QR sign-in — the QR opens in a dialog that
/// polls until the phone confirms, then closes itself and stores the cookie —
/// because that is a *login*, not a cookie to paste. 手动输入 stays available
/// underneath, and a signed-in account can be logged out here.
class AccountBilibiliPage extends ConsumerStatefulWidget {
  const AccountBilibiliPage({super.key});

  @override
  ConsumerState<AccountBilibiliPage> createState() => _AccountBilibiliPageState();
}

class _AccountBilibiliPageState extends ConsumerState<AccountBilibiliPage> {
  String _message = '';

  Future<void> _openQrLogin() async {
    await showBilibiliQrLoginDialog(context, ref);
    if (!mounted) return;
    final CookieModel cookies = ref.read(cookieControllerProvider);
    setState(() => _message = cookies.bilibiliCookie.isEmpty ? '' : i18n('logined'));
  }

  Future<void> _logout() async {
    final bool? confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('logout'),
      message: i18n('logout_bilibili_confirm'),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
    );
    if (confirmed != true) return;
    ref.read(cookieControllerProvider.notifier).setBilibiliCookie('');
    await BilibiliAccountService.instance.logout();
    if (!mounted) return;
    setState(() => _message = i18n('cookie_saved'));
  }

  @override
  Widget build(BuildContext context) {
    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final theme = context.tvTheme;
    final bool logined = cookies.bilibiliCookie.isNotEmpty;

    return AccountCookiePage(
      platform: CookiePlatform(
        siteId: Sites.bilibiliSite,
        name: i18n('site_bilibili'),
        hint: i18n('cookie_hint', args: {'name': i18n('site_bilibili')}),
        read: (model) => model.bilibiliCookie,
        apply: (value) => ref.read(cookieControllerProvider.notifier).setBilibiliCookie(value),
        webPath: null,
      ),
      loginPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('qr_login')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('qr_login'),
                subtitle: logined
                    ? (cookies.bilibiliUid <= 0 ? i18n('logined') : 'UID ${cookies.bilibiliUid}')
                    : i18n('qr_login_tip'),
                leading: SiteLogo(siteId: Sites.bilibiliSite, size: 34),
                onTap: () => unawaited(_openQrLogin()),
              ),
              if (logined)
                TvSettingsOptionTile(
                  title: i18n('logout'),
                  subtitle: i18n('logout_bilibili_confirm'),
                  icon: Remix.logout_box_r_line,
                  options: [i18n('logout')],
                  index: 0,
                  onChanged: (_) => unawaited(_logout()),
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

/// The device-QR sign-in dialog: generate, show, poll, and close itself the
/// moment the phone confirms.
///
/// The polling lives here rather than on the page so the QR is a single
/// self-contained step: the user scans, the dialog says 已扫描 while the phone
/// is confirming, and on success it stores the cookie and pops — no OK button to
/// hunt for with a remote.
Future<void> showBilibiliQrLoginDialog(BuildContext context, WidgetRef ref) {
  return TvDialogUtils.show<void>(context: context, builder: (_) => const _BilibiliQrLoginDialog());
}

class _BilibiliQrLoginDialog extends ConsumerStatefulWidget {
  const _BilibiliQrLoginDialog();

  @override
  ConsumerState<_BilibiliQrLoginDialog> createState() => _BilibiliQrLoginDialogState();
}

class _BilibiliQrLoginDialogState extends ConsumerState<_BilibiliQrLoginDialog> {
  static const Duration _pollInterval = Duration(seconds: 3);

  final BiliBiliQrLoginService _service = BiliBiliQrLoginService();
  Timer? _timer;
  BiliBiliQrStatus _status = BiliBiliQrStatus.loading;
  String _qrUrl = '';
  String _qrKey = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _timer?.cancel();
    setState(() {
      _status = BiliBiliQrStatus.loading;
      _error = '';
      _qrKey = '';
    });
    try {
      final BiliBiliQrSession session = await _service.generate();
      if (!mounted) return;
      setState(() {
        _qrUrl = session.url;
        _qrKey = session.key;
        _status = BiliBiliQrStatus.unscanned;
      });
      _timer = Timer.periodic(_pollInterval, (_) => _poll());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = BiliBiliQrStatus.failed;
        _error = '$error';
      });
    }
  }

  Future<void> _poll() async {
    final String key = _qrKey;
    if (key.isEmpty) return;
    try {
      final BiliBiliQrPoll result = await _service.poll(key);
      if (!mounted) return;
      switch (result.status) {
        case BiliBiliQrStatus.success:
          // The callback the whole dialog waits for: store the cookie and get
          // out of the way.
          _timer?.cancel();
          ref.read(cookieControllerProvider.notifier).setBilibiliCookie(result.cookie);
          Navigator.of(context).pop();
        case BiliBiliQrStatus.scanned:
          setState(() => _status = BiliBiliQrStatus.scanned);
        case BiliBiliQrStatus.expired:
          _timer?.cancel();
          setState(() => _status = BiliBiliQrStatus.expired);
        case BiliBiliQrStatus.unscanned:
        case BiliBiliQrStatus.loading:
        case BiliBiliQrStatus.failed:
          break;
      }
    } catch (_) {
      // Transient polling failures are expected while the phone is offline.
    }
  }

  String get _statusText => switch (_status) {
    BiliBiliQrStatus.loading => i18n('ui_loading'),
    BiliBiliQrStatus.unscanned => i18n('qr_login_tip'),
    BiliBiliQrStatus.scanned => i18n('qr_scanned'),
    BiliBiliQrStatus.success => i18n('logined'),
    BiliBiliQrStatus.expired => i18n('qr_expired'),
    BiliBiliQrStatus.failed => i18n('qr_load_failed'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final bool showQr = _qrUrl.isNotEmpty && _status != BiliBiliQrStatus.expired;

    return TvDialog(
      title: '${i18n('qr_login')} · ${i18n('site_bilibili')}',
      cancelText: i18n('cancel'),
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              height: 360.sp,
              child: switch (_status) {
                BiliBiliQrStatus.loading => AppStatusView(
                  type: AppStatusType.loading,
                  subtitle: i18n('ui_loading'),
                  isMini: true,
                ),
                // Waiting for the phone: the QR is up, then the confirmation
                // state spins so the user knows the scan registered.
                BiliBiliQrStatus.unscanned => TvQrCodeCard(qrData: _qrUrl),
                BiliBiliQrStatus.scanned => AppStatusView(
                  type: AppStatusType.loading,
                  subtitle: i18n('qr_scanned'),
                  isMini: true,
                ),
                BiliBiliQrStatus.expired => AppStatusView(
                  type: AppStatusType.error,
                  title: i18n('qr_expired'),
                  subtitle: i18n('qr_refresh_tip'),
                  buttonText: i18n('refresh_qr'),
                  onTap: () => unawaited(_load()),
                  isMini: true,
                ),
                BiliBiliQrStatus.failed => AppStatusView(
                  type: AppStatusType.error,
                  title: i18n('qr_load_failed'),
                  subtitle: _error,
                  buttonText: i18n('retry'),
                  onTap: () => unawaited(_load()),
                  isMini: true,
                ),
                BiliBiliQrStatus.success => AppStatusView(type: AppStatusType.empty, title: i18n('logined'), isMini: true),
              },
            ),
          ),
          if (showQr && _status != BiliBiliQrStatus.scanned) ...[
            SizedBox(height: 12.sp),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
            ),
          ],
        ],
      ),
    );
  }
}
