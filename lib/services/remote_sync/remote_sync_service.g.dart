// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bridges the storage-free [TvRemoteKit] to the app's controllers.
///
/// Channel reads/writes land on the real services (cookies, danmaku shield
/// words, tags, proxy, IPTV, full settings), and phone pushes are forwarded
/// into the same [TvRemoteReceiver] callbacks the web remote already drives —
/// so every page that listens for phone input needs no change at all.

@ProviderFor(RemoteSyncController)
final remoteSyncControllerProvider = RemoteSyncControllerProvider._();

/// Bridges the storage-free [TvRemoteKit] to the app's controllers.
///
/// Channel reads/writes land on the real services (cookies, danmaku shield
/// words, tags, proxy, IPTV, full settings), and phone pushes are forwarded
/// into the same [TvRemoteReceiver] callbacks the web remote already drives —
/// so every page that listens for phone input needs no change at all.
final class RemoteSyncControllerProvider
    extends $NotifierProvider<RemoteSyncController, RemoteSyncSnapshot> {
  /// Bridges the storage-free [TvRemoteKit] to the app's controllers.
  ///
  /// Channel reads/writes land on the real services (cookies, danmaku shield
  /// words, tags, proxy, IPTV, full settings), and phone pushes are forwarded
  /// into the same [TvRemoteReceiver] callbacks the web remote already drives —
  /// so every page that listens for phone input needs no change at all.
  RemoteSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteSyncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteSyncControllerHash();

  @$internal
  @override
  RemoteSyncController create() => RemoteSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteSyncSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteSyncSnapshot>(value),
    );
  }
}

String _$remoteSyncControllerHash() =>
    r'0274cce3c3ffc842ceedc143eb2913b44d539577';

/// Bridges the storage-free [TvRemoteKit] to the app's controllers.
///
/// Channel reads/writes land on the real services (cookies, danmaku shield
/// words, tags, proxy, IPTV, full settings), and phone pushes are forwarded
/// into the same [TvRemoteReceiver] callbacks the web remote already drives —
/// so every page that listens for phone input needs no change at all.

abstract class _$RemoteSyncController extends $Notifier<RemoteSyncSnapshot> {
  RemoteSyncSnapshot build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RemoteSyncSnapshot, RemoteSyncSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RemoteSyncSnapshot, RemoteSyncSnapshot>,
              RemoteSyncSnapshot,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
