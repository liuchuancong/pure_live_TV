// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotTabs)
final hotTabsProvider = HotTabsProvider._();

final class HotTabsProvider extends $NotifierProvider<HotTabs, HotTabsState> {
  HotTabsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotTabsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotTabsHash();

  @$internal
  @override
  HotTabs create() => HotTabs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HotTabsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HotTabsState>(value),
    );
  }
}

String _$hotTabsHash() => r'63bc6e7cadef045d44eebbee74d1ec257271fea2';

abstract class _$HotTabs extends $Notifier<HotTabsState> {
  HotTabsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HotTabsState, HotTabsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HotTabsState, HotTabsState>,
              HotTabsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
