// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_remote_receiver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TvRemoteReceiver)
final tvRemoteReceiverProvider = TvRemoteReceiverProvider._();

final class TvRemoteReceiverProvider
    extends $AsyncNotifierProvider<TvRemoteReceiver, ServerState> {
  TvRemoteReceiverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvRemoteReceiverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvRemoteReceiverHash();

  @$internal
  @override
  TvRemoteReceiver create() => TvRemoteReceiver();
}

String _$tvRemoteReceiverHash() => r'8d7c2fdd1ebdeb959956c49008ec207021bc66cb';

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
