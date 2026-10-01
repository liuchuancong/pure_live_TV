import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pure_live/core/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';

/// One saved Bilibili account in the multi-account roster.
///
/// Mirrors the source project's `UserEntity`: a uid, the display name, an
/// optional avatar URL, the login cookie and a per-account lock PIN. [lock] is
/// a sequence of D-Pad direction letters (`u`/`d`/`l`/`r`); an empty string
/// means the account has no lock.
class BilibiliRosterAccount {
  BilibiliRosterAccount({
    required this.uid,
    required this.username,
    required this.avatar,
    required this.cookie,
    this.lock = '',
  });

  int uid;
  String username;
  String avatar;
  String cookie;
  String lock;

  bool get hasLock => lock.isNotEmpty;

  String get displayLabel => username.isNotEmpty ? username : 'UID $uid';

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'avatar': avatar,
    'cookie': cookie,
    'lock': lock,
  };

  factory BilibiliRosterAccount.fromJson(Map<String, dynamic> json) => BilibiliRosterAccount(
    uid: (json['uid'] as num?)?.toInt() ?? 0,
    username: json['username'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    cookie: json['cookie'] as String? ?? '',
    lock: json['lock'] as String? ?? '',
  );
}

/// The set of signed-in Bilibili accounts, persisted to preferences.
///
/// The app keeps exactly one *active* account (the cookie/uid in
/// [CookieController]); this roster remembers every account that has signed in
/// so the user can switch between them without re-scanning, and lets an
/// individual account be guarded by a D-Pad PIN that is required to launch into
/// it. It is a plain [ChangeNotifier] singleton so it can be read and written
/// from non-widget code (the account-info commit path) as well as watched by
/// the account page.
class BilibiliAccountRoster extends ChangeNotifier {
  BilibiliAccountRoster._() {
    _load();
  }

  static final BilibiliAccountRoster instance = BilibiliAccountRoster._();

  static const String _key = 'bilibiliAccountRoster';

  final List<BilibiliRosterAccount> _accounts = <BilibiliRosterAccount>[];

  /// Accounts whose lock has been satisfied since this process started, so the
  /// user is not asked for the PIN again on every in-app switch.
  final Set<int> _unlockedThisSession = <int>{};

  /// Whether the startup unlock screen has been dismissed this session.
  bool _startupCleared = false;

  void _load() {
    try {
      _accounts
        ..clear()
        ..addAll(HivePrefUtil.getObjectList<BilibiliRosterAccount>(_key, BilibiliRosterAccount.fromJson));
    } catch (_) {
      // A corrupt entry must never brick sign-in; start from an empty roster.
    }
  }

  List<BilibiliRosterAccount> get accounts => List<BilibiliRosterAccount>.unmodifiable(_accounts);

  int get currentUid => SettingsService.to.isInitialized ? SettingsService.to.cookieState.bilibiliUid : 0;

  BilibiliRosterAccount? byUid(int uid) {
    for (final BilibiliRosterAccount account in _accounts) {
      if (account.uid == uid) return account;
    }
    return null;
  }

  bool isCurrent(int uid) => uid != 0 && uid == currentUid;

  void _persist() {
    unawaited(HivePrefUtil.setObjectList<BilibiliRosterAccount>(_key, _accounts, (a) => a.toJson()));
    notifyListeners();
  }

  /// Adds or refreshes the entry for an account whose info just loaded. The
  /// existing lock PIN is preserved across refreshes.
  void recordActive({required int uid, required String username, required String cookie, String avatar = ''}) {
    if (uid <= 0) return;
    final BilibiliRosterAccount? existing = byUid(uid);
    if (existing == null) {
      _accounts.add(BilibiliRosterAccount(uid: uid, username: username, avatar: avatar, cookie: cookie));
    } else {
      existing.cookie = cookie;
      if (username.isNotEmpty) existing.username = username;
      if (avatar.isNotEmpty) existing.avatar = avatar;
    }
    _persist();
  }

  /// Sets (or clears, with an empty [lock]) the PIN for [uid].
  void setLock(int uid, String lock) {
    BilibiliRosterAccount? account = byUid(uid);
    if (account == null && uid > 0 && uid == currentUid && SettingsService.to.isInitialized) {
      // The active account is being locked before its roster entry has synced
      // (a race right after sign-in): create it from the live session.
      account = BilibiliRosterAccount(
        uid: uid,
        username: '',
        avatar: '',
        cookie: SettingsService.to.cookieState.bilibiliCookie,
      );
      _accounts.add(account);
    }
    if (account == null) return;
    account.lock = lock;
    if (lock.isEmpty) {
      _unlockedThisSession.remove(uid);
    } else {
      _unlockedThisSession.add(uid);
    }
    _persist();
  }

  /// Removes an account from the roster. Does not touch the active session; the
  /// caller is responsible for logging out when deleting the current account.
  void remove(int uid) {
    _accounts.removeWhere((a) => a.uid == uid);
    _unlockedThisSession.remove(uid);
    _persist();
  }

  /// Switches the active session to a saved account by applying its cookie,
  /// which in turn reloads the account info and re-syncs the roster entry.
  void switchTo(int uid) {
    final BilibiliRosterAccount? account = byUid(uid);
    if (account == null) return;
    if (uid != 0) SettingsService.to.cookieManager.setBilibiliUid(uid);
    SettingsService.to.cookieManager.setBilibiliCookie(account.cookie);
  }

  bool isLocked(int uid) {
    final BilibiliRosterAccount? account = byUid(uid);
    return account != null && account.lock.isNotEmpty;
  }

  bool hasAnyLock() => _accounts.any((a) => a.lock.isNotEmpty);

  bool isUnlockedThisSession(int uid) => _unlockedThisSession.contains(uid);

  void markUnlocked(int uid) {
    if (uid <= 0) return;
    _unlockedThisSession.add(uid);
    notifyListeners();
  }

  /// Whether the launch-time unlock screen should be shown: there is at least
  /// one locked account and the user has not cleared it since the app started.
  bool get showStartupUnlock => !_startupCleared && hasAnyLock();

  void clearStartupUnlock() {
    if (_startupCleared) return;
    _startupCleared = true;
    notifyListeners();
  }
}
