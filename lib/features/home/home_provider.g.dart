// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(myProfileMenuItem)
final myProfileMenuItemProvider = MyProfileMenuItemProvider._();

final class MyProfileMenuItemProvider
    extends $FunctionalProvider<AppMenuItem, AppMenuItem, AppMenuItem>
    with $Provider<AppMenuItem> {
  MyProfileMenuItemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileMenuItemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileMenuItemHash();

  @$internal
  @override
  $ProviderElement<AppMenuItem> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppMenuItem create(Ref ref) {
    return myProfileMenuItem(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMenuItem value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMenuItem>(value),
    );
  }
}

String _$myProfileMenuItemHash() => r'c9e00e6e4ebc6c9d250c3a089ea1e54ebb0a8c4c';

@ProviderFor(sideMenuList)
final sideMenuListProvider = SideMenuListProvider._();

final class SideMenuListProvider
    extends
        $FunctionalProvider<
          List<AppMenuItem>,
          List<AppMenuItem>,
          List<AppMenuItem>
        >
    with $Provider<List<AppMenuItem>> {
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

String _$sideMenuListHash() => r'6ad90c2ae87c4648a026f98bb397c84e28eb8540';

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
    r'9433aed46076f3347f406a36acf7d45760e6846c';

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
