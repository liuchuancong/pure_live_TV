// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_remote_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotRemote)
final hotRemoteProvider = HotRemoteFamily._();

final class HotRemoteProvider
    extends $NotifierProvider<HotRemote, BasePagedState<LiveRoom>> {
  HotRemoteProvider._({
    required HotRemoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hotRemoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hotRemoteHash();

  @override
  String toString() {
    return r'hotRemoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HotRemote create() => HotRemote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BasePagedState<LiveRoom> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BasePagedState<LiveRoom>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HotRemoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hotRemoteHash() => r'401ad73a824656fb7fef12adf09b6b4a7ed72a23';

final class HotRemoteFamily extends $Family
    with
        $ClassFamilyOverride<
          HotRemote,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          BasePagedState<LiveRoom>,
          String
        > {
  HotRemoteFamily._()
    : super(
        retry: null,
        name: r'hotRemoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HotRemoteProvider call(String siteId) =>
      HotRemoteProvider._(argument: siteId, from: this);

  @override
  String toString() => r'hotRemoteProvider';
}

abstract class _$HotRemote extends $Notifier<BasePagedState<LiveRoom>> {
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
