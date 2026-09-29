// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide mode, persisted: the TV boots into whatever mode was last
/// used instead of always live.

@ProviderFor(AppModeController)
final appModeControllerProvider = AppModeControllerProvider._();

/// The app-wide mode, persisted: the TV boots into whatever mode was last
/// used instead of always live.
final class AppModeControllerProvider
    extends $NotifierProvider<AppModeController, AppMode> {
  /// The app-wide mode, persisted: the TV boots into whatever mode was last
  /// used instead of always live.
  AppModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appModeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appModeControllerHash();

  @$internal
  @override
  AppModeController create() => AppModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMode>(value),
    );
  }
}

String _$appModeControllerHash() => r'03cbcf9b93a41e4607a55b94f6e70096031d461f';

/// The app-wide mode, persisted: the TV boots into whatever mode was last
/// used instead of always live.

abstract class _$AppModeController extends $Notifier<AppMode> {
  AppMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppMode, AppMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppMode, AppMode>,
              AppMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Selected music-mode sidebar section (index into [MusicSection.values]).

@ProviderFor(MusicSectionIndex)
final musicSectionIndexProvider = MusicSectionIndexProvider._();

/// Selected music-mode sidebar section (index into [MusicSection.values]).
final class MusicSectionIndexProvider
    extends $NotifierProvider<MusicSectionIndex, int> {
  /// Selected music-mode sidebar section (index into [MusicSection.values]).
  MusicSectionIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicSectionIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicSectionIndexHash();

  @$internal
  @override
  MusicSectionIndex create() => MusicSectionIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$musicSectionIndexHash() => r'32fcba090186c5b398739776561d37b00600bb1a';

/// Selected music-mode sidebar section (index into [MusicSection.values]).

abstract class _$MusicSectionIndex extends $Notifier<int> {
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

/// Selected video-mode sidebar section (index into [VideoSection.values]).

@ProviderFor(VideoSectionIndex)
final videoSectionIndexProvider = VideoSectionIndexProvider._();

/// Selected video-mode sidebar section (index into [VideoSection.values]).
final class VideoSectionIndexProvider
    extends $NotifierProvider<VideoSectionIndex, int> {
  /// Selected video-mode sidebar section (index into [VideoSection.values]).
  VideoSectionIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoSectionIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoSectionIndexHash();

  @$internal
  @override
  VideoSectionIndex create() => VideoSectionIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$videoSectionIndexHash() => r'c361cb5410239c21e5fc80a79526d03f191df058';

/// Selected video-mode sidebar section (index into [VideoSection.values]).

abstract class _$VideoSectionIndex extends $Notifier<int> {
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
    r'41646141c3fba521181f43a17c10f834f09e4174';

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
