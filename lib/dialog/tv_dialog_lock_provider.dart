import 'package:riverpod_annotation/riverpod_annotation.dart';

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
