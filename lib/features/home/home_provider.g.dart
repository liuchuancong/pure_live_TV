// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Side menu entries in the order configured in settings, limited to the
/// visible ones. An empty configuration shows every entry in default order.

@ProviderFor(sideMenuList)
final sideMenuListProvider = SideMenuListProvider._();

/// Side menu entries in the order configured in settings, limited to the
/// visible ones. An empty configuration shows every entry in default order.

final class SideMenuListProvider
    extends
        $FunctionalProvider<
          List<AppMenuItem>,
          List<AppMenuItem>,
          List<AppMenuItem>
        >
    with $Provider<List<AppMenuItem>> {
  /// Side menu entries in the order configured in settings, limited to the
  /// visible ones. An empty configuration shows every entry in default order.
  SideMenuListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sideMenuListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sideMenuListHash();

  @$internal
  @override
  $ProviderElement<List<AppMenuItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<AppMenuItem> create(Ref ref) {
    return sideMenuList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AppMenuItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AppMenuItem>>(value),
    );
  }
}

String _$sideMenuListHash() => r'f3ee494bfa97ddfe57931521b8dbf60b7618872d';

@ProviderFor(mySettingsMenuItem)
final mySettingsMenuItemProvider = MySettingsMenuItemProvider._();

final class MySettingsMenuItemProvider
    extends $FunctionalProvider<AppMenuItem, AppMenuItem, AppMenuItem>
    with $Provider<AppMenuItem> {
  MySettingsMenuItemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySettingsMenuItemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySettingsMenuItemHash();

  @$internal
  @override
  $ProviderElement<AppMenuItem> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppMenuItem create(Ref ref) {
    return mySettingsMenuItem(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMenuItem value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMenuItem>(value),
    );
  }
}

String _$mySettingsMenuItemHash() =>
    r'2b12b2dba8b31b80ad49d3a6ecb8bd5b54265f06';

@ProviderFor(SideMenuIndex)
final sideMenuIndexProvider = SideMenuIndexProvider._();

final class SideMenuIndexProvider
    extends $NotifierProvider<SideMenuIndex, int> {
  SideMenuIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sideMenuIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sideMenuIndexHash();

  @$internal
  @override
  SideMenuIndex create() => SideMenuIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$sideMenuIndexHash() => r'9add5f52fe930fb0289219740ce6e684aea4651f';

abstract class _$SideMenuIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(IsMenuExpanded)
final isMenuExpandedProvider = IsMenuExpandedProvider._();

final class IsMenuExpandedProvider
    extends $NotifierProvider<IsMenuExpanded, bool> {
  IsMenuExpandedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isMenuExpandedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isMenuExpandedHash();

  @$internal
  @override
  IsMenuExpanded create() => IsMenuExpanded();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isMenuExpandedHash() => r'598d50c35faf3c61e534df456cdbca4a42bda573';

abstract class _$IsMenuExpanded extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
