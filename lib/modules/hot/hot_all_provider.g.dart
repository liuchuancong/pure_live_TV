// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_all_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotAll)
final hotAllProvider = HotAllFamily._();

final class HotAllProvider
    extends $NotifierProvider<HotAll, BasePagedState<LiveRoom>> {
  HotAllProvider._({
    required HotAllFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hotAllProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hotAllHash();

  @override
  String toString() {
    return r'hotAllProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HotAll create() => HotAll();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BasePagedState<LiveRoom> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BasePagedState<LiveRoom>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HotAllProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hotAllHash() => r'45beac1a282103a1b2b2964d2a76d0033a1bf638';

final class HotAllFamily extends $Family
    with
        $ClassFamilyOverride<
          HotAll,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          String
        > {
  HotAllFamily._()
    : super(
        retry: null,
        name: r'hotAllProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HotAllProvider call(String siteId) =>
      HotAllProvider._(argument: siteId, from: this);

  @override
  String toString() => r'hotAllProvider';
}

abstract class _$HotAll extends $Notifier<BasePagedState<LiveRoom>> {
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
