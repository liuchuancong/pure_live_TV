import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_qr_login_service.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_roster.dart';
import 'package:pure_live/features/settings/pages/widgets/account_lock.dart';

/// Bilibili: the account page. QR sign-in only — the manual cookie paste was
/// removed, because that flow invited broken logins; the device-QR sign-in
/// writes the session the moment the phone confirms, and a signed-in account
/// can log out here.
///
/// Multiple accounts are kept in [BilibiliAccountRoster]: the list shows every
/// signed-in account, tapping one opens its actions (switch / lock / delete),
/// and an account can be guarded by a D-Pad PIN that is required to launch into
/// it. See [showUserLockSettings] and [StartupUnlockView].
class AccountBilibiliPage extends ConsumerStatefulWidget {
  const AccountBilibiliPage({super.key});

  @override
  ConsumerState<AccountBilibiliPage> createState() => _AccountBilibiliPageState();
}

enum _AccountAction { switchTo, lock, delete }

class _AccountBilibiliPageState extends ConsumerState<AccountBilibiliPage> {
  String _message = '';

  @override
  Widget build(BuildContext context) {
    final CookieModel cookies = ref.watch(cookieControllerProvider);
    final BilibiliAccountModel account = ref.watch(bilibiliAccountControllerProvider);
    final theme = context.tvTheme;
    final bool logined = cookies.bilibiliCookie.isNotEmpty;
    final double contentHeight = MediaQuery.sizeOf(context).height -
        kToolbarHeight -
        MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: contentHeight,
      child: Align(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 660.ts(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Signed-in accounts: switch / lock / delete. The active cookie
                // stays the source of truth for playback; the roster is the set
                // of accounts that have signed in and can be returned to.
                ListenableBuilder(
                  listenable: BilibiliAccountRoster.instance,
                  builder: (context, _) {
                    final List<BilibiliRosterAccount> accounts = _displayAccounts(cookies, account);
                    if (accounts.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TvSettingsGroupTitle(title: i18n('account_saved_accounts')),
                        TvSettingsCard(
                          children: [
                            for (final BilibiliRosterAccount a in accounts)
                              _AccountTile(
                                account: a,
                                isCurrent: cookies.bilibiliUid > 0 && a.uid == cookies.bilibiliUid,
                                onSelected: () => _showActions(a, cookies),
                              ),
                            TvSettingsNavTile(
                              title: i18n('account_add'),
                              icon: Icons.add_rounded,
                              onTap: () => showBilibiliQrLoginDialog(context, ref),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                // First sign-in: the QR is straight on screen, no dialog to enter.
                if (!logined) ...[
                  SizedBox(height: 12.ts(context)),
                  TvSettingsGroupTitle(title: i18n('qr_login')),
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
                ],

                if (_message.isNotEmpty) ...[
                  SizedBox(height: 16.ts(context)),
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
      ),
    );
  }

  /// The roster plus a virtual row for the active account when it has not synced
  /// yet (a fresh sign-in, or a pre-roster upgrade), so it is always manageable.
  List<BilibiliRosterAccount> _displayAccounts(CookieModel cookies, BilibiliAccountModel account) {
    final List<BilibiliRosterAccount> list = BilibiliAccountRoster.instance.accounts;
    if (cookies.bilibiliUid > 0 && list.every((a) => a.uid != cookies.bilibiliUid)) {
      return <BilibiliRosterAccount>[
        BilibiliRosterAccount(
          uid: cookies.bilibiliUid,
          username: account.name,
          avatar: '',
          cookie: cookies.bilibiliCookie,
        ),
        ...list,
      ];
    }
    return list;
  }

  Future<void> _showActions(BilibiliRosterAccount a, CookieModel cookies) async {
    final bool isCurrent = cookies.bilibiliUid > 0 && a.uid == cookies.bilibiliUid;
    final List<TvSelectItem<_AccountAction>> items = <TvSelectItem<_AccountAction>>[
      if (!isCurrent) TvSelectItem(title: i18n('account_switch_to'), value: _AccountAction.switchTo),
      TvSelectItem(title: i18n('account_password_lock'), value: _AccountAction.lock),
      TvSelectItem(title: i18n('account_delete'), value: _AccountAction.delete),
    ];

    final _AccountAction? action = await TvDialogUtils.showSelect<_AccountAction>(
      context: context,
      title: a.displayLabel,
      items: items,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _AccountAction.switchTo:
        BilibiliAccountRoster.instance.switchTo(a.uid);
      case _AccountAction.lock:
        await showUserLockSettings(context);
      case _AccountAction.delete:
        await _delete(a, isCurrent);
    }
  }

  Future<void> _delete(BilibiliRosterAccount a, bool isCurrent) async {
    final bool? confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('account_delete'),
      message: a.displayLabel,
      confirmText: i18n('delete'),
      cancelText: i18n('cancel'),
    );
    if (confirmed != true) return;
    final BilibiliAccountRoster roster = BilibiliAccountRoster.instance;
    if (isCurrent) {
      // Deleting the active account signs out: the roster entry would otherwise
      // still hand back a cookie that no longer represents who is logged in.
      ref.read(cookieControllerProvider.notifier).setBilibiliCookie('');
      await BilibiliAccountService.instance.logout();
    }
    roster.remove(a.uid);
  }
}

/// One saved account: avatar, name, a current/locked hint, and a lock glyph.
class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.isCurrent, required this.onSelected});

  final BilibiliRosterAccount account;
  final bool isCurrent;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final String label = account.displayLabel;
    final String subtitle = isCurrent ? i18n('account_current') : 'UID ${account.uid}';
    final double size = 40.ts(context);
    return TvSettingsNavTile(
      title: label,
      subtitle: subtitle,
      leading: CircleAvatar(
        radius: size / 2,
        backgroundColor: theme.cardColor,
        foregroundImage: account.avatar.isEmpty ? null : NetworkImage(account.avatar),
        child: Text(
          label.isEmpty ? '?' : label[0],
          style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: theme.primaryTextColor),
        ),
      ),
      trailing: account.lock.isEmpty
          ? null
          : Icon(Icons.lock_outline_rounded, size: 22.ts(context), color: theme.focusColor),
      onTap: onSelected,
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
            style: AppTextStyles.t20.copyWith(
              fontWeight: FontWeight.w500,
              color: context.tvTheme.secondaryTextColor,
            ),
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
