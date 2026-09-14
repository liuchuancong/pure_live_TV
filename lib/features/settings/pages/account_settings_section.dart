import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
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
    final cookieState = ref.watch(cookieControllerProvider);
    final cookie = ref.read(cookieControllerProvider.notifier);
    final theme = context.tvTheme;
    final showQr = !account.isLogined && _qrUrl.isNotEmpty;

    // Platforms whose public pages need a signed-in cookie; every row edits the
    // same cookie store the sites and the player already read.
    final platforms = <_CookiePlatform>[
      _CookiePlatform(
        name: i18n('site_huya'),
        hint: i18n('huya_cookie_hint'),
        value: cookieState.huyaCookie,
        apply: cookie.setHuyaCookie,
      ),
      _CookiePlatform(
        name: i18n('site_douyin'),
        hint: i18n('douyin_cookie_hint'),
        value: cookieState.douyinCookie,
        apply: cookie.setDouyinCookie,
      ),
      _CookiePlatform(
        name: i18n('site_kuaishou'),
        hint: i18n('kuaishou_cookie_hint'),
        value: cookieState.kuaishouCookie,
        apply: cookie.setKuaishouCookie,
      ),
      _CookiePlatform(
        name: i18n('site_yy'),
        hint: i18n('cookie_hint', args: {'name': i18n('site_yy')}),
        value: cookieState.yyCookie,
        apply: cookie.setYyCookie,
      ),
      _CookiePlatform(
        name: i18n('site_soop'),
        hint: i18n('soop_cookie_hint'),
        value: cookieState.soopCookie,
        apply: cookie.setSoopCookie,
      ),
      _CookiePlatform(
        name: i18n('site_twitch'),
        hint: i18n('twitch_cookie_hint'),
        value: cookieState.twitchCookie,
        apply: cookie.setTwitchCookie,
      ),
    ];

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
          SizedBox(height: 16.h),
          TvSettingsCard(
            children: [
              for (final platform in platforms)
                TvSettingsOptionTile(
                  title: platform.name,
                  subtitle: platform.value.isEmpty
                      ? i18n('not_set')
                      : i18n('cookie_state_set', args: {'count': '${platform.value.length}'}),
                  icon: platform.value.isEmpty ? Icons.cookie_outlined : Icons.cookie_rounded,
                  options: [i18n('set_cookie')],
                  index: 0,
                  onChanged: (_) => _editCookie(context, platform),
                ),
              TvSettingsOptionTile(
                title: i18n('clear_all_cookies'),
                subtitle: i18n('clear_all_cookies_desc'),
                icon: Icons.delete_sweep_outlined,
                options: [i18n('clear')],
                index: 0,
                onChanged: (_) => _clearCookies(context, cookie),
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

  Future<void> _editCookie(BuildContext context, _CookiePlatform platform) async {
    final result = await TvDialogUtils.show<String>(
      context: context,
      builder: (dialogContext) => _CookieEditorDialog(
        platformName: platform.name,
        hintText: platform.hint,
        initialValue: platform.value,
      ),
    );
    if (result == null) return;
    platform.apply(result);
    if (!mounted) return;
    setState(() => _message = i18n('cookie_saved'));
  }

  Future<void> _clearCookies(BuildContext context, CookieController cookie) async {
    final confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('clear_all_cookies'),
      message: i18n('clear_all_cookies_desc'),
      confirmText: i18n('clear'),
      cancelText: i18n('cancel'),
      onConfirm: cookie.clearAllCookies,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _message = i18n('cookie_saved'));
  }
}

/// One editable cookie row: the display name, the paste hint and the current
/// value read from the shared cookie store.
class _CookiePlatform {
  const _CookiePlatform({required this.name, required this.hint, required this.value, required this.apply});

  final String name;
  final String hint;
  final String value;
  final ValueChanged<String> apply;
}

/// Cookie editor used by the account page.
///
/// The value is a long browser header, so the field wraps over several lines
/// and confirming an unchanged field still returns the current value.
class _CookieEditorDialog extends StatefulWidget {
  const _CookieEditorDialog({required this.platformName, required this.hintText, required this.initialValue});

  final String platformName;
  final String hintText;
  final String initialValue;

  @override
  State<_CookieEditorDialog> createState() => _CookieEditorDialogState();
}

class _CookieEditorDialogState extends State<_CookieEditorDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvDialog(
      title: '${i18n('set_cookie')} · ${widget.platformName}',
      confirmText: i18n('save'),
      cancelText: i18n('cancel'),
      onConfirm: _submit,
      onCancel: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              i18n('cookie_tip', args: {'name': widget.platformName}),
              style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 20.sp),
            ),
            SizedBox(height: 16.sp),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(color: tvTheme.primaryTextColor, fontSize: 22.sp),
              cursorColor: tvTheme.focusColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: tvTheme.secondaryTextColor.withAlpha(120), fontSize: 20.sp),
                filled: true,
                fillColor: tvTheme.backgroundColor.withAlpha(100),
                contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.sp), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.sp),
                  borderSide: BorderSide(color: tvTheme.focusColor, width: 2.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
