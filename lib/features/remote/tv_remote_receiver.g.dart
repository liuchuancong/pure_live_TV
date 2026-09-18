// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_remote_receiver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// LAN services (web remote on 8888, plus the callbacks every page binds for
/// phone pushes) live for the whole session: auto-dispose tore the server down
/// whenever the page that happened to start it was left, and an in-flight
/// start could then write `state` after disposal and crash the isolate.

@ProviderFor(TvRemoteReceiver)
final tvRemoteReceiverProvider = TvRemoteReceiverProvider._();

/// LAN services (web remote on 8888, plus the callbacks every page binds for
/// phone pushes) live for the whole session: auto-dispose tore the server down
/// whenever the page that happened to start it was left, and an in-flight
/// start could then write `state` after disposal and crash the isolate.
final class TvRemoteReceiverProvider
    extends $AsyncNotifierProvider<TvRemoteReceiver, ServerState> {
  /// LAN services (web remote on 8888, plus the callbacks every page binds for
  /// phone pushes) live for the whole session: auto-dispose tore the server down
  /// whenever the page that happened to start it was left, and an in-flight
  /// start could then write `state` after disposal and crash the isolate.
  TvRemoteReceiverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvRemoteReceiverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvRemoteReceiverHash();

  @$internal
  @override
  TvRemoteReceiver create() => TvRemoteReceiver();
}

String _$tvRemoteReceiverHash() => r'6ce2d82bf6e0b4255f4cccb261e35f521e73c9eb';

/// LAN services (web remote on 8888, plus the callbacks every page binds for
/// phone pushes) live for the whole session: auto-dispose tore the server down
/// whenever the page that happened to start it was left, and an in-flight
/// start could then write `state` after disposal and crash the isolate.

abstract class _$TvRemoteReceiver extends $AsyncNotifier<ServerState> {
  FutureOr<ServerState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ServerState>, ServerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerState>, ServerState>,
              AsyncValue<ServerState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
