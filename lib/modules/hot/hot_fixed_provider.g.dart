// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_fixed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotFixed)
final hotFixedProvider = HotFixedFamily._();

final class HotFixedProvider
    extends $NotifierProvider<HotFixed, BasePagedState<LiveRoom>> {
  HotFixedProvider._({
    required HotFixedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hotFixedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hotFixedHash();

  @override
  String toString() {
    return r'hotFixedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HotFixed create() => HotFixed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BasePagedState<LiveRoom> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BasePagedState<LiveRoom>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HotFixedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hotFixedHash() => r'6965453003a2e377c0720da76f892543fa2080ce';

final class HotFixedFamily extends $Family
    with
        $ClassFamilyOverride<
          HotFixed,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          String
        > {
  HotFixedFamily._()
    : super(
        retry: null,
        name: r'hotFixedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HotFixedProvider call(String siteId) =>
      HotFixedProvider._(argument: siteId, from: this);

  @override
  String toString() => r'hotFixedProvider';
}

abstract class _$HotFixed extends $Notifier<BasePagedState<LiveRoom>> {
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
