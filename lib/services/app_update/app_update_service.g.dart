// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Online update for the TV build: version check through the existing
/// [VersionUtil] mirror race, release history from `assets/releases.json`,
/// APK download with mirror fallback and progress, then the package installer.

@ProviderFor(AppUpdateController)
final appUpdateControllerProvider = AppUpdateControllerProvider._();

/// Online update for the TV build: version check through the existing
/// [VersionUtil] mirror race, release history from `assets/releases.json`,
/// APK download with mirror fallback and progress, then the package installer.
final class AppUpdateControllerProvider
    extends $NotifierProvider<AppUpdateController, AppUpdateState> {
  /// Online update for the TV build: version check through the existing
  /// [VersionUtil] mirror race, release history from `assets/releases.json`,
  /// APK download with mirror fallback and progress, then the package installer.
  AppUpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateControllerHash();

  @$internal
  @override
  AppUpdateController create() => AppUpdateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdateState>(value),
    );
  }
}

String _$appUpdateControllerHash() =>
    r'0a64746ee57fbdf1eede6269d08ca1c3836f8c59';

/// Online update for the TV build: version check through the existing
/// [VersionUtil] mirror race, release history from `assets/releases.json`,
/// APK download with mirror fallback and progress, then the package installer.

abstract class _$AppUpdateController extends $Notifier<AppUpdateState> {
  AppUpdateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppUpdateState, AppUpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppUpdateState, AppUpdateState>,
              AppUpdateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
