import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/account_cookie_page.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Bilibili: the account page, so it has more than the other platforms.
///
/// 扫码 is the app's own device-QR sign-in (the mobile app's flow: generate,
/// poll every 3 s, store the cookie the server returns). 手动输入 is shared with
/// every other platform, and a signed-in account can be logged out here.
class AccountBilibiliPage extends ConsumerStatefulWidget {
  const AccountBilibiliPage({super.key});

  @override
  ConsumerState<AccountBilibiliPage> createState() => _AccountBilibiliPageState();
}

class _AccountBilibiliPageState extends ConsumerState<AccountBilibiliPage> {
  static const Duration _pollInterval = Duration(seconds: 3);

  final BiliBiliQrLoginService _service = BiliBiliQrLoginService();
  Timer? _timer;
  BiliBiliQrStatus _status = BiliBiliQrStatus.loading;
  String _qrUrl = '';
  String _qrKey = '';
  String _message = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQrCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQrCode() async {
    _timer?.cancel();
    setState(() {
      _status = BiliBiliQrStatus.loading;
      _message = '';
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
        _message = '$error';
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
          setState(() {
            _status = BiliBiliQrStatus.success;
            _message = i18n('logined');
          });
        case BiliBiliQrStatus.scanned:
          setState(() => _status = BiliBiliQrStatus.scanned);
        case BiliBiliQrStatus.expired:
          _timer?.cancel();
          setState(() {
            _status = BiliBiliQrStatus.expired;
            _message = i18n('qr_expired');
          });
        case BiliBiliQrStatus.unscanned:
        case BiliBiliQrStatus.loading:
        case BiliBiliQrStatus.failed:
          break;
      }
    } catch (_) {
      // Transient polling failures are expected while the phone is offline.
    }
  }

  Future<void> _logout() async {
    _timer?.cancel();
    ref.read(cookieControllerProvider.notifier).setBilibiliCookie('');
    await BilibiliAccountService.instance.logout();
    if (!mounted) return;
    setState(() => _message = i18n('cookie_saved'));
    await _loadQrCode();
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
    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final theme = context.tvTheme;
    final bool logined = cookies.bilibiliCookie.isNotEmpty;
    final bool showQr = !logined && _qrUrl.isNotEmpty;

    return AccountCookiePage(
      platform: CookiePlatform(
        name: i18n('site_bilibili'),
        hint: i18n('cookie_hint', args: {'name': i18n('site_bilibili')}),
        read: (model) => model.bilibiliCookie,
        apply: (value) => ref.read(cookieControllerProvider.notifier).setBilibiliCookie(value),
        // The phone page only carries a cookie; the native QR below does the
        // actual sign-in, so the bridge row would be a worse duplicate.
        webPath: null,
      ),
      showPhoneBridge: false,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('site_bilibili')),
          TvSettingsCard(
            children: [
              if (showQr)
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      TvQrCodeCard(qrData: _qrUrl, urlText: _statusText),
                      SizedBox(height: 12.h),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    logined ? i18n('logined') : _statusText,
                    style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
                  ),
                ),
              TvSettingsOptionTile(
                title: i18n('refresh_qr'),
                icon: Remix.refresh_line,
                options: [i18n('refresh_qr')],
                index: 0,
                onChanged: (_) => _loadQrCode(),
              ),
              if (logined)
                TvSettingsOptionTile(
                  title: i18n('logout'),
                  subtitle: i18n('logout_bilibili_confirm'),
                  icon: Remix.logout_box_r_line,
                  options: [i18n('logout')],
                  index: 0,
                  onChanged: (_) => _logout(),
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
