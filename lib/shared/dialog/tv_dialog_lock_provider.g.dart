// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_dialog_lock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TvDialogLock)
final tvDialogLockProvider = TvDialogLockProvider._();

final class TvDialogLockProvider extends $NotifierProvider<TvDialogLock, bool> {
  TvDialogLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvDialogLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvDialogLockHash();

  @$internal
  @override
  TvDialogLock create() => TvDialogLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tvDialogLockHash() => r'3f8de0f4aa94eb9f802dcaf13d1dc8e0f9938561';

abstract class _$TvDialogLock extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
