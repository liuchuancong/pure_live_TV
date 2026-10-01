import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_roster.dart';

/// Error tint for a wrong PIN. The TV palette has no error colour, so the lock
/// flow carries its own.
const Color _kLockErrorColor = Color(0xFFFF6B6B);

final Set<LogicalKeyboardKey> _kConfirmKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.gameButtonA,
};

final Set<LogicalKeyboardKey> _kBackKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.backspace,
  LogicalKeyboardKey.browserBack,
  LogicalKeyboardKey.goBack,
};

String _directionLetter(LogicalKeyboardKey key) => switch (key) {
  LogicalKeyboardKey.arrowUp => 'u',
  LogicalKeyboardKey.arrowDown => 'd',
  LogicalKeyboardKey.arrowLeft => 'l',
  LogicalKeyboardKey.arrowRight => 'r',
  _ => '',
};

/// A single D-Pad PIN capture.
///
/// It reads the arrow keys through a global [HardwareKeyboard] handler rather
/// than a [Focus], and consumes them, so the app's D-Pad focus-traversal layer
/// never sees the arrows that make up the password. Up/down/left/right append
/// `u`/`d`/`l`/`r`; the centre/OK key submits; Back deletes the last entry and,
/// on an empty buffer, hands control to [onEmptyBack].
///
/// Bump [resetToken] to clear the buffer (e.g. after a wrong attempt) without
/// rebuilding the surrounding flow.
class DPadPinInput extends StatefulWidget {
  const DPadPinInput({
    super.key,
    required this.prompt,
    required this.onSubmit,
    required this.onEmptyBack,
    this.masked = false,
    this.hint,
    this.message = '',
    this.resetToken = 0,
  });

  final String prompt;
  final ValueChanged<String> onSubmit;
  final VoidCallback onEmptyBack;
  final bool masked;
  final String? hint;
  final String message;
  final int resetToken;

  @override
  State<DPadPinInput> createState() => _DPadPinInputState();
}

class _DPadPinInputState extends State<DPadPinInput> {
  final StringBuffer _buffer = StringBuffer();
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DPadPinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) _buffer.clear();
  }

  void _register() {
    if (_registered) return;
    HardwareKeyboard.instance.addHandler(_onKey);
    _registered = true;
  }

  void _unregister() {
    if (!_registered) return;
    HardwareKeyboard.instance.removeHandler(_onKey);
    _registered = false;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyUpEvent) return false;
    final LogicalKeyboardKey key = event.logicalKey;
    final String letter = _directionLetter(key);
    if (letter.isNotEmpty) {
      if (_buffer.length < 24) setState(() => _buffer.write(letter));
      return true;
    }
    if (_kConfirmKeys.contains(key)) {
      widget.onSubmit(_buffer.toString());
      return true;
    }
    if (_kBackKeys.contains(key)) {
      _handleBack();
      return true;
    }
    return false;
  }

  void _handleBack() {
    if (_buffer.isEmpty) {
      widget.onEmptyBack();
      return;
    }
    final String s = _buffer.toString();
    setState(() {
      _buffer
        ..clear()
        ..write(s.substring(0, s.length - 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final String pin = _buffer.toString();
    final String display = widget.masked
        ? '*' * pin.length
        : pin.split('').map((c) => switch (c) {
            'u' => '↑',
            'd' => '↓',
            'l' => '←',
            'r' => '→',
            _ => c,
          }).join();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.prompt,
          textAlign: TextAlign.center,
          style: AppTextStyles.t28.copyWith(fontWeight: FontWeight.w600, color: theme.primaryTextColor),
        ),
        SizedBox(height: 28.ts(context)),
        SizedBox(
          height: 52.ts(context),
          child: Center(
            child: Text(
              display.isEmpty ? ' ' : display,
              style: AppTextStyles.t28.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 8.ts(context),
                color: theme.focusColor,
              ),
            ),
          ),
        ),
        if (widget.message.isNotEmpty) ...[
          SizedBox(height: 12.ts(context)),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w500, color: _kLockErrorColor),
          ),
        ],
        if (widget.hint != null) ...[
          SizedBox(height: 20.ts(context)),
          Text(
            widget.hint!,
            textAlign: TextAlign.center,
            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w300, color: theme.secondaryTextColor),
          ),
        ],
      ],
    );
  }
}

/// A dark centred panel for the lock dialogs. They own their key handling, so
/// they deliberately do not reuse [TvDialog], whose OK/Cancel chrome would
/// fight the D-Pad capture.
class _LockDialogShell extends StatelessWidget {
  const _LockDialogShell({required this.child, this.onCancel});

  final Widget child;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onCancel ?? () => Navigator.of(context).pop(),
            child: ColoredBox(color: Colors.black.withAlpha(180)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 720.ts(context)),
              child: Container(
                margin: EdgeInsets.all(24.ts(context)),
                padding: EdgeInsets.symmetric(horizontal: 40.ts(context), vertical: 48.ts(context)),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18.ts(context)),
                  border: Border.all(color: theme.focusColor.withAlpha(90)),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "set / change / clear lock" flow for the current account — the source's
/// three-state machine (verify old when a lock exists, enter new, confirm; an
/// empty new PIN clears the lock).
class UserLockSettingsView extends StatefulWidget {
  const UserLockSettingsView({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<UserLockSettingsView> createState() => _UserLockSettingsViewState();
}

enum _LockStep { inputOld, inputNew, confirm }

class _UserLockSettingsViewState extends State<UserLockSettingsView> {
  late final int _uid;
  late String _existingLock;
  _LockStep _step = _LockStep.inputNew;
  String _pendingNew = '';
  String _message = '';
  int _token = 0;

  @override
  void initState() {
    super.initState();
    final BilibiliAccountRoster roster = BilibiliAccountRoster.instance;
    _uid = roster.currentUid;
    _existingLock = roster.byUid(_uid)?.lock ?? '';
    if (_existingLock.isNotEmpty) _step = _LockStep.inputOld;
  }

  String get _prompt => switch (_step) {
    _LockStep.inputOld => i18n('lock_input_old'),
    _LockStep.inputNew => i18n('lock_set_new'),
    _LockStep.confirm => i18n('lock_confirm_new'),
  };

  void _submit(String pin) {
    setState(() {
      _message = '';
      _token++;
      switch (_step) {
        case _LockStep.inputOld:
          if (pin == _existingLock) {
            _step = _LockStep.inputNew;
          } else {
            _message = i18n('lock_wrong_password');
          }
        case _LockStep.inputNew:
          if (pin.isEmpty) {
            BilibiliAccountRoster.instance.setLock(_uid, '');
            widget.onChanged?.call();
            Navigator.of(context).pop();
            return;
          }
          _pendingNew = pin;
          _step = _LockStep.confirm;
        case _LockStep.confirm:
          if (pin == _pendingNew) {
            BilibiliAccountRoster.instance.setLock(_uid, pin);
            widget.onChanged?.call();
            Navigator.of(context).pop();
            return;
          }
          _message = i18n('lock_mismatch');
          _step = _LockStep.inputNew;
      }
    });
  }

  void _emptyBack() {
    if (_step == _LockStep.confirm) {
      setState(() {
        _step = _LockStep.inputNew;
        _message = '';
        _token++;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _LockDialogShell(
      onCancel: () => Navigator.of(context).pop(),
      child: DPadPinInput(
        prompt: _prompt,
        masked: false,
        message: _message,
        resetToken: _token,
        hint: _step == _LockStep.inputNew ? i18n('lock_hint_blank_remove') : null,
        onSubmit: _submit,
        onEmptyBack: _emptyBack,
      ),
    );
  }
}

/// Opens the lock settings flow for the current account.
Future<void> showUserLockSettings(BuildContext context) {
  return TvDialogUtils.show<void>(
    context: context,
    builder: (_) => const UserLockSettingsView(),
  );
}

/// The launch-time unlock screen (source `UnlockUserScreen`): choose an account,
/// then enter its PIN when it is locked. Fully self-contained — it drives its own
/// selection with a global key handler because it renders outside the D-Pad
/// focus layer.
class StartupUnlockView extends StatefulWidget {
  const StartupUnlockView({super.key});

  @override
  State<StartupUnlockView> createState() => _StartupUnlockViewState();
}

class _StartupUnlockViewState extends State<StartupUnlockView> {
  bool _choosing = true;
  int _selIndex = 0;
  final StringBuffer _pin = StringBuffer();
  String _message = '';

  final BilibiliAccountRoster _roster = BilibiliAccountRoster.instance;
  BilibiliRosterAccount? _selected;

  List<BilibiliRosterAccount> get _accounts => _roster.accounts;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyUpEvent) return false;
    final LogicalKeyboardKey key = event.logicalKey;
    if (_choosing) {
      if (_accounts.isEmpty) return false;
      if (key == LogicalKeyboardKey.arrowLeft) {
        setState(() => _selIndex = (_selIndex - 1 + _accounts.length) % _accounts.length);
        return true;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        setState(() => _selIndex = (_selIndex + 1) % _accounts.length);
        return true;
      }
      if (_kConfirmKeys.contains(key)) {
        _pick(_accounts[_selIndex.clamp(0, _accounts.length - 1)]);
        return true;
      }
      return false;
    }

    // Password entry for the selected account.
    final String letter = _directionLetter(key);
    if (letter.isNotEmpty) {
      if (_pin.length < 24) setState(() => _pin.write(letter));
      return true;
    }
    if (_kConfirmKeys.contains(key)) {
      _submitPin();
      return true;
    }
    if (_kBackKeys.contains(key)) {
      if (_pin.isEmpty) {
        setState(() {
          _choosing = true;
          _selected = null;
        });
      } else {
        final String s = _pin.toString();
        setState(() {
          _pin
            ..clear()
            ..write(s.substring(0, s.length - 1));
        });
      }
      return true;
    }
    return false;
  }

  void _pick(BilibiliRosterAccount account) {
    if (account.lock.isEmpty) {
      _enter(account);
      return;
    }
    setState(() {
      _selected = account;
      _choosing = false;
      _pin.clear();
      _message = '';
    });
  }

  void _submitPin() {
    final BilibiliRosterAccount? account = _selected;
    if (account == null) return;
    if (_pin.toString() == account.lock) {
      _enter(account);
      return;
    }
    setState(() {
      _message = i18n('lock_wrong_password');
      _pin.clear();
    });
  }

  void _enter(BilibiliRosterAccount account) {
    if (!_roster.isCurrent(account.uid)) _roster.switchTo(account.uid);
    _roster.markUnlocked(account.uid);
    _roster.clearStartupUnlock();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final String pin = _pin.toString();
    final String masked = '*' * pin.length;

    return Container(
      color: theme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 72.ts(context)),
            Text(
              _choosing ? i18n('lock_choose_user') : i18n('lock_input_password'),
              style: AppTextStyles.t28.copyWith(fontWeight: FontWeight.w700, color: theme.primaryTextColor),
            ),
            Expanded(
              child: _choosing ? _buildChooser(context) : _buildPassword(context, masked.isEmpty ? ' ' : masked),
            ),
            SizedBox(height: 56.ts(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChooser(BuildContext context) {
    final theme = context.tvTheme;
    if (_accounts.isEmpty) {
      return Center(
        child: Text(
          i18n('account_no_users'),
          style: AppTextStyles.t20.copyWith(color: theme.secondaryTextColor),
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 32.ts(context)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _accounts.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.ts(context)),
                child: _UnlockCard(account: _accounts[i], focused: i == _selIndex),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassword(BuildContext context, String display) {
    final theme = context.tvTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selected?.displayLabel ?? '',
            style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: theme.primaryTextColor),
          ),
          SizedBox(height: 24.ts(context)),
          SizedBox(
            height: 52.ts(context),
            child: Center(
              child: Text(
                display,
                style: AppTextStyles.t28.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8.ts(context),
                  color: theme.focusColor,
                ),
              ),
            ),
          ),
          if (_message.isNotEmpty) ...[
            SizedBox(height: 12.ts(context)),
            Text(
              _message,
              style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w500, color: _kLockErrorColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({required this.account, required this.focused});

  final BilibiliRosterAccount account;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final double avatar = 76.ts(context);
    final String label = account.displayLabel;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 148.ts(context),
      padding: EdgeInsets.all(16.ts(context)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.ts(context)),
        border: Border.all(color: focused ? theme.focusColor : Colors.transparent, width: 2),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: theme.focusColor.withAlpha(theme.isLight ? 160 : 100),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: avatar / 2,
            backgroundColor: theme.backgroundColor,
            foregroundImage: account.avatar.isEmpty ? null : NetworkImage(account.avatar),
            child: Text(
              label.isEmpty ? '?' : label[0],
              style: AppTextStyles.t28.copyWith(fontWeight: FontWeight.w600, color: theme.primaryTextColor),
            ),
          ),
          SizedBox(height: 10.ts(context)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: theme.primaryTextColor),
          ),
          SizedBox(height: 6.ts(context)),
          Icon(
            account.lock.isEmpty ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            size: 18.ts(context),
            color: account.lock.isEmpty ? theme.secondaryTextColor : theme.focusColor,
          ),
        ],
      ),
    );
  }
}

int focusGlowAlpha(dynamic theme) => (theme.isLight == true) ? 160 : 100;

/// Sits above the whole app and blocks it with the launch unlock screen until a
/// locked account is satisfied. Renders nothing when no account is locked.
class AccountStartupGate extends StatefulWidget {
  const AccountStartupGate({super.key});

  @override
  State<AccountStartupGate> createState() => _AccountStartupGateState();
}

class _AccountStartupGateState extends State<AccountStartupGate> {
  final BilibiliAccountRoster _roster = BilibiliAccountRoster.instance;

  @override
  void initState() {
    super.initState();
    _roster.addListener(_onChanged);
  }

  @override
  void dispose() {
    _roster.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_roster.showStartupUnlock) return const SizedBox.shrink();
    return const Positioned.fill(child: StartupUnlockView());
  }
}
