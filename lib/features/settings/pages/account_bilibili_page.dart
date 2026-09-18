import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/account_cookie_page.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Bilibili: the account page, so it has more than the other platforms.
///
/// 扫码登录 is the app's own device-QR sign-in: the QR is shown **directly in
/// the left column** ([BilibiliQrLoginView]) and polls until the phone
/// confirms, because that is a *login*, not a cookie to paste. 手动输入 stays
/// available underneath, and a signed-in account can be logged out here.
class AccountBilibiliPage extends ConsumerStatefulWidget {
  const AccountBilibiliPage({super.key});

  @override
  ConsumerState<AccountBilibiliPage> createState() => _AccountBilibiliPageState();
}

class _AccountBilibiliPageState extends ConsumerState<AccountBilibiliPage> {
  String _message = '';

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
        webPath: '/#/cookie/bilibili',
      ),
      // The left column is the sign-in itself: the QR is on screen the moment
      // the page opens, no dialog to enter first.
      loginPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('qr_login')),
          TvSettingsCard(
            children: [
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: BilibiliQrLoginView(
                  onLogined: () {
                    if (mounted) setState(() => _message = i18n('logined'));
                  },
                ),
              ),
              if (logined)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cookies.bilibiliUid > 0 ? 'UID ${cookies.bilibiliUid}' : i18n('logined'),
                          style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
                        ),
                      ),
                      TvButton(
                        title: i18n('logout'),
                        size: TvButtonSize.small,
                        isSecondary: true,
                        icon: Icon(Remix.logout_box_r_line, size: 18.sp),
                        onTap: () => unawaited(_logout()),
                      ),
                    ],
                  ),
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

/// The device-QR sign-in, as an embeddable view: generate, poll, and store the
/// cookie the moment the phone confirms.
///
/// One state machine for both homes — the account page's left column (the QR
/// straight on screen) and the [showBilibiliQrLoginDialog] wrapper. Success
/// writes the cookie and reports through [onLogined]; expiry and load failures
/// offer their own refresh/retry button instead of leaving a dead code behind.
class BilibiliQrLoginView extends ConsumerStatefulWidget {
  const BilibiliQrLoginView({super.key, this.onLogined, this.compact = false});

  /// Fires once, after the confirmed login was stored.
  final VoidCallback? onLogined;

  /// Tighter status views for the embedded column; the dialog keeps the
  /// roomier default.
  final bool compact;

  @override
  ConsumerState<BilibiliQrLoginView> createState() => _BilibiliQrLoginViewState();
}

class _BilibiliQrLoginViewState extends ConsumerState<BilibiliQrLoginView> {
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
          _timer?.cancel();
          ref.read(cookieControllerProvider.notifier).setBilibiliCookie(result.cookie);
          setState(() => _status = BiliBiliQrStatus.success);
          widget.onLogined?.call();
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
    final double statusHeight = (widget.compact ? 220 : 360).sp;

    Widget body = SizedBox(
      height: statusHeight,
      child: switch (_status) {
        BiliBiliQrStatus.loading => AppStatusView(type: AppStatusType.loading, subtitle: i18n('ui_loading'), isMini: true),
        // Waiting for the phone: the QR is up, then the confirmation state
        // spins so the user knows the scan registered.
        BiliBiliQrStatus.unscanned => TvQrCodeCard(qrData: _qrUrl),
        BiliBiliQrStatus.scanned => AppStatusView(type: AppStatusType.loading, subtitle: i18n('qr_scanned'), isMini: true),
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: body),
        if (_status != BiliBiliQrStatus.scanned && _status != BiliBiliQrStatus.loading) ...[
          SizedBox(height: 12.sp),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: AppTextStyles.t16W500.copyWith(color: context.tvTheme.secondaryTextColor),
          ),
        ],
      ],
    );
  }
}

/// The device-QR sign-in as a dialog: the embedded [BilibiliQrLoginView] plus
/// the dialog chrome, popping itself the moment the login lands.
Future<void> showBilibiliQrLoginDialog(BuildContext context, WidgetRef ref) {
  return TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: '${i18n('qr_login')} · ${i18n('site_bilibili')}',
      cancelText: i18n('cancel'),
      onCancel: () => Navigator.of(context).pop(),
      child: BilibiliQrLoginView(
        onLogined: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
