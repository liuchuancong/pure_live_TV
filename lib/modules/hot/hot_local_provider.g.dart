// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_local_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotLocal)
final hotLocalProvider = HotLocalFamily._();

final class HotLocalProvider
    extends $NotifierProvider<HotLocal, BasePagedState<LiveRoom>> {
  HotLocalProvider._({
    required HotLocalFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hotLocalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hotLocalHash();

  @override
  String toString() {
    return r'hotLocalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HotLocal create() => HotLocal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BasePagedState<LiveRoom> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BasePagedState<LiveRoom>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HotLocalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hotLocalHash() => r'1d0d52858fafe91ef7a2e539ca313d469254772e';

final class HotLocalFamily extends $Family
    with
        $ClassFamilyOverride<
          HotLocal,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          String
        > {
  HotLocalFamily._()
    : super(
        retry: null,
        name: r'hotLocalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HotLocalProvider call(String siteId) =>
      HotLocalProvider._(argument: siteId, from: this);

  @override
  String toString() => r'hotLocalProvider';
}

abstract class _$HotLocal extends $Notifier<BasePagedState<LiveRoom>> {
  late final _$args = ref.$arg as String;
  String get siteId => _$args;

  BasePagedState<LiveRoom> build(String siteId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<BasePagedState<LiveRoom>, BasePagedState<LiveRoom>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BasePagedState<LiveRoom>, BasePagedState<LiveRoom>>,
              BasePagedState<LiveRoom>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
