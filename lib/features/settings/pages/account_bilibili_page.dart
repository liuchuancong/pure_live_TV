import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';

/// Bilibili: the account page. QR sign-in only — the manual cookie paste was
/// removed, because that flow invited broken logins; the device-QR sign-in
/// writes the session the moment the phone confirms, and a signed-in account
/// can log out here.
class AccountBilibiliPage extends ConsumerStatefulWidget {
  const AccountBilibiliPage({super.key});

  @override
  ConsumerState<AccountBilibiliPage> createState() => _AccountBilibiliPageState();
}

class _AccountBilibiliPageState extends ConsumerState<AccountBilibiliPage> {
  String _message = '';

  @override
  Widget build(BuildContext context) {
    final CookieModel cookies = ref.watch(cookieControllerProvider);
    // The nickname loads right after a cookie exists; until it lands the UID
    // stays as the fallback label.
    final BilibiliAccountModel account = ref.watch(bilibiliAccountControllerProvider);
    final theme = context.tvTheme;
    final bool logined = cookies.bilibiliCookie.isNotEmpty;
    final double contentHeight = MediaQuery.sizeOf(context).height - kToolbarHeight - MediaQuery.paddingOf(context).top;
    // Routed through SettingsSectionScaffold (see settingsSection in app_router):
    // it already owns the title bar and the scroll view, and a scaffold of our
    // own inside it sits under unbounded height and crashes the layout.
    //
    // One centred column: the sign-in first (the QR is on screen the moment the
    // page opens, no dialog to enter first), then who is signed in. Nothing is
    // shown for "not signed in" — the QR above already says what to do, and a
    // line announcing the absence of an account is noise.
    return SizedBox(
      height: contentHeight,
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 660.ts(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!logined) TvSettingsGroupTitle(title: i18n('qr_login')),
              if (!logined)
                TvSettingsCard(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.ts(context)),
                      child: BilibiliQrLoginView(
                        onLogined: () {
                          if (mounted) setState(() => _message = i18n('logined'));
                        },
                      ),
                    ),
                  ],
                ),

              if (logined) ...[
                TvSettingsGroupTitle(title: i18n('site_bilibili')),
                TvSettingsCard(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(18.ts(context)),
                      child: Row(
                        children: [
                          Icon(Icons.account_circle_rounded, size: 52.ts(context), color: theme.focusColor),
                          SizedBox(width: 16.ts(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // The nickname is the answer to "who is signed in",
                                // so it is the line that gets the size; the UID
                                // only stands in until the account request lands.
                                Text(
                                  account.name.isNotEmpty
                                      ? account.name
                                      : (cookies.bilibiliUid > 0 ? 'UID ${cookies.bilibiliUid}' : i18n('logined')),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.t28.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryTextColor,
                                  ),
                                ),
                                if (account.name.isNotEmpty && cookies.bilibiliUid > 0) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    'UID ${cookies.bilibiliUid}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.t16.copyWith(
                                      fontWeight: FontWeight.w300,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 16.ts(context)),
                          TvButton(
                            title: i18n('logout'),
                            size: TvButtonSize.medium,
                            isSecondary: true,
                            icon: Icon(Icons.logout_rounded, size: 22.ts(context)),
                            onTap: () {
                              ref.read(cookieControllerProvider.notifier).setBilibiliCookie('');
                              if (mounted) setState(() => _message = '');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              if (_message.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20.ts(context), color: theme.focusColor),
                    SizedBox(width: 8.ts(context)),
                    Text(
                      _message,
                      style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: theme.focusColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
  const BilibiliQrLoginView({super.key, this.onLogined});

  final VoidCallback? onLogined;

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
    final double statusHeight = 300.ts(context);

    Widget body = SizedBox(
      height: statusHeight,
      child: switch (_status) {
        BiliBiliQrStatus.loading => AppStatusView(
          type: AppStatusType.loading,
          subtitle: i18n('ui_loading'),
          isMini: true,
        ),
        // Waiting for the phone: the QR is up, then the confirmation state
        // spins so the user knows the scan registered.
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
        BiliBiliQrStatus.success => Container(),
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: body),
        if (_status != BiliBiliQrStatus.scanned && _status != BiliBiliQrStatus.loading) ...[
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w500, color: context.tvTheme.secondaryTextColor),
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
      child: BilibiliQrLoginView(onLogined: () => Navigator.of(context).pop()),
    ),
  );
}
