// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Danmaku session for one room: owns the transport connection, message
/// gating and duplicate filtering, and fans messages out to the overlay and
/// the list view. Filter thresholds come from the global danmaku settings.

@ProviderFor(DanmakuSessionController)
final danmakuSessionControllerProvider = DanmakuSessionControllerFamily._();

/// Danmaku session for one room: owns the transport connection, message
/// gating and duplicate filtering, and fans messages out to the overlay and
/// the list view. Filter thresholds come from the global danmaku settings.
final class DanmakuSessionControllerProvider
    extends $NotifierProvider<DanmakuSessionController, DanmakuSessionState> {
  /// Danmaku session for one room: owns the transport connection, message
  /// gating and duplicate filtering, and fans messages out to the overlay and
  /// the list view. Filter thresholds come from the global danmaku settings.
  DanmakuSessionControllerProvider._({
    required DanmakuSessionControllerFamily super.from,
    required LivePlayArgs super.argument,
  }) : super(
         retry: null,
         name: r'danmakuSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$danmakuSessionControllerHash();

  @override
  String toString() {
    return r'danmakuSessionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DanmakuSessionController create() => DanmakuSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DanmakuSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DanmakuSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DanmakuSessionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$danmakuSessionControllerHash() =>
    r'80fd1c0bf0b6fc930629114c579eedcb93aa7214';

/// Danmaku session for one room: owns the transport connection, message
/// gating and duplicate filtering, and fans messages out to the overlay and
/// the list view. Filter thresholds come from the global danmaku settings.

final class DanmakuSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DanmakuSessionController,
          DanmakuSessionState,
          DanmakuSessionState,
          DanmakuSessionState,
          LivePlayArgs
        > {
  DanmakuSessionControllerFamily._()
    : super(
        retry: null,
        name: r'danmakuSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Danmaku session for one room: owns the transport connection, message
  /// gating and duplicate filtering, and fans messages out to the overlay and
  /// the list view. Filter thresholds come from the global danmaku settings.

  DanmakuSessionControllerProvider call(LivePlayArgs args) =>
      DanmakuSessionControllerProvider._(argument: args, from: this);

  @override
  String toString() => r'danmakuSessionControllerProvider';
}

/// Danmaku session for one room: owns the transport connection, message
/// gating and duplicate filtering, and fans messages out to the overlay and
/// the list view. Filter thresholds come from the global danmaku settings.

abstract class _$DanmakuSessionController
    extends $Notifier<DanmakuSessionState> {
  late final _$args = ref.$arg as LivePlayArgs;
  LivePlayArgs get args => _$args;

  DanmakuSessionState build(LivePlayArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DanmakuSessionState, DanmakuSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DanmakuSessionState, DanmakuSessionState>,
              DanmakuSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
