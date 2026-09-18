// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Device sync only: mDNS broadcast + discovery over bonsoir and a small HTTP
/// server on 39888 (walking upwards when taken). Same logic as the web side's
/// `RemoteSyncService`, hosted in Riverpod for the TV pages.

@ProviderFor(RemoteSyncController)
final remoteSyncControllerProvider = RemoteSyncControllerProvider._();

/// Device sync only: mDNS broadcast + discovery over bonsoir and a small HTTP
/// server on 39888 (walking upwards when taken). Same logic as the web side's
/// `RemoteSyncService`, hosted in Riverpod for the TV pages.
final class RemoteSyncControllerProvider
    extends $NotifierProvider<RemoteSyncController, RemoteSyncSnapshot> {
  /// Device sync only: mDNS broadcast + discovery over bonsoir and a small HTTP
  /// server on 39888 (walking upwards when taken). Same logic as the web side's
  /// `RemoteSyncService`, hosted in Riverpod for the TV pages.
  RemoteSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteSyncControllerProvider',
        isAutoDispose: true,
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
    r'10e4eba3e38d77fda44a4fd26024dac387f4ba93';

/// Device sync only: mDNS broadcast + discovery over bonsoir and a small HTTP
/// server on 39888 (walking upwards when taken). Same logic as the web side's
/// `RemoteSyncService`, hosted in Riverpod for the TV pages.

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
