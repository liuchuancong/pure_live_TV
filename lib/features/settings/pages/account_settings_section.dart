import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';

/// Bilibili account page: QR-code login plus logout for the signed-in account.
class AccountSettingsSectionPage extends ConsumerStatefulWidget {
  const AccountSettingsSectionPage({super.key});

  @override
  ConsumerState<AccountSettingsSectionPage> createState() => AccountSettingsSectionPageState();
}

class AccountSettingsSectionPageState extends ConsumerState<AccountSettingsSectionPage> {
  static const Duration _pollInterval = Duration(seconds: 3);

  final _service = BiliBiliQrLoginService();
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
      final session = await _service.generate();
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
    final key = _qrKey;
    if (key.isEmpty) return;
    try {
      final result = await _service.poll(key);
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
    setState(() {
      _message = i18n('cookie_saved');
      _status = BiliBiliQrStatus.loading;
    });
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
    final account = ref.watch(bilibiliAccountControllerProvider);
    final theme = context.tvTheme;
    final showQr = !account.isLogined && _qrUrl.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('bilibili_login'),
                subtitle: account.isLogined
                    ? '${account.name}  UID ${account.uid}'
                    : i18n('qr_login_tip'),
                icon: account.isLogined ? Icons.verified_user_rounded : Icons.qr_code_rounded,
                options: [i18n('ui_refresh')],
                index: 0,
                onChanged: (_) => _loadQrCode(),
              ),
              if (account.isLogined)
                TvSettingsOptionTile(
                  title: i18n('logout'),
                  subtitle: i18n('logout_bilibili_confirm'),
                  icon: Icons.logout_rounded,
                  options: [i18n('logout')],
                  index: 0,
                  onChanged: (_) => _logout(),
                ),
            ],
          ),
          if (showQr) ...[
            SizedBox(height: 16.h),
            Center(child: TvQrCodeCard(qrData: _qrUrl, urlText: _qrUrl)),
          ],
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 14.h),
            child: Text(_message.isEmpty ? _statusText : '$_statusText · $_message',
                style: TextStyle(fontSize: 14.sp, color: theme.primaryTextColor)),
          ),
        ],
      ),
    );
  }
}
