import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/services/settings/settings.dart';

part 'tv_dialog_lock_provider.g.dart';

@Riverpod(keepAlive: true)
class TvDialogLock extends _$TvDialogLock {
  @override
  bool build() => false;

  void lock() => state = true;

  Future<void> unlock() async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = false;
  }
}

/// Whether a [TvDialog] currently owns the remote. A focusable card must drop
/// BOTH its select and long-select while this is true, so a disturbed keypress
/// (the release of the hold that opened the dialog, or a fresh press landing on
/// a card behind it) never opens a second dialog or acts under the open one.
/// Every long-press card reads this: see [TvRoomCard] for the reference.
bool get tvDialogLockedNow => SettingsService.to.container?.read(tvDialogLockProvider) ?? false;
