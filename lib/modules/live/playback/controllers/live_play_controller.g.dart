// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_play_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives one live room: detail/quality/URL fetching, playback state
/// projection, quality and line switching. Danmaku sessions live in
/// [DanmakuSessionController].

@ProviderFor(LivePlayController)
final livePlayControllerProvider = LivePlayControllerFamily._();

/// Drives one live room: detail/quality/URL fetching, playback state
/// projection, quality and line switching. Danmaku sessions live in
/// [DanmakuSessionController].
final class LivePlayControllerProvider
    extends $NotifierProvider<LivePlayController, LivePlayState> {
  /// Drives one live room: detail/quality/URL fetching, playback state
  /// projection, quality and line switching. Danmaku sessions live in
  /// [DanmakuSessionController].
  LivePlayControllerProvider._({
    required LivePlayControllerFamily super.from,
    required LivePlayArgs super.argument,
  }) : super(
         retry: null,
         name: r'livePlayControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$livePlayControllerHash();

  @override
  String toString() {
    return r'livePlayControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LivePlayController create() => LivePlayController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LivePlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LivePlayState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LivePlayControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$livePlayControllerHash() =>
    r'a20ea55b6bf55efc5a482f7a3445f9d3964840a5';

/// Drives one live room: detail/quality/URL fetching, playback state
/// projection, quality and line switching. Danmaku sessions live in
/// [DanmakuSessionController].

final class LivePlayControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LivePlayController,
          LivePlayState,
          LivePlayState,
          LivePlayState,
          LivePlayArgs
        > {
  LivePlayControllerFamily._()
    : super(
        retry: null,
        name: r'livePlayControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives one live room: detail/quality/URL fetching, playback state
  /// projection, quality and line switching. Danmaku sessions live in
  /// [DanmakuSessionController].

  LivePlayControllerProvider call(LivePlayArgs args) =>
      LivePlayControllerProvider._(argument: args, from: this);

  @override
  String toString() => r'livePlayControllerProvider';
}

/// Drives one live room: detail/quality/URL fetching, playback state
/// projection, quality and line switching. Danmaku sessions live in
/// [DanmakuSessionController].

abstract class _$LivePlayController extends $Notifier<LivePlayState> {
  late final _$args = ref.$arg as LivePlayArgs;
  LivePlayArgs get args => _$args;

  LivePlayState build(LivePlayArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LivePlayState, LivePlayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LivePlayState, LivePlayState>,
              LivePlayState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
