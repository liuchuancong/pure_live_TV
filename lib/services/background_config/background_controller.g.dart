// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Background configuration and the player behind a video background.
///
/// keepAlive: the video player and its [VideoController] are created here, and
/// the background layer only *reads* this provider. As auto-dispose it was
/// disposed between reads and rebuilt on the next one, so every rebuild created
/// a new `Player`/`VideoController` and disposed the previous one — the
/// `VideoOutputManager.create` → `dispose` → `Resize 0x0` →
/// `Surface.release()` NPE in logcat, plus a reloading wallpaper.

@ProviderFor(BackgroundController)
final backgroundControllerProvider = BackgroundControllerProvider._();

/// Background configuration and the player behind a video background.
///
/// keepAlive: the video player and its [VideoController] are created here, and
/// the background layer only *reads* this provider. As auto-dispose it was
/// disposed between reads and rebuilt on the next one, so every rebuild created
/// a new `Player`/`VideoController` and disposed the previous one — the
/// `VideoOutputManager.create` → `dispose` → `Resize 0x0` →
/// `Surface.release()` NPE in logcat, plus a reloading wallpaper.
final class BackgroundControllerProvider
    extends $NotifierProvider<BackgroundController, BackgroundConfigModel> {
  /// Background configuration and the player behind a video background.
  ///
  /// keepAlive: the video player and its [VideoController] are created here, and
  /// the background layer only *reads* this provider. As auto-dispose it was
  /// disposed between reads and rebuilt on the next one, so every rebuild created
  /// a new `Player`/`VideoController` and disposed the previous one — the
  /// `VideoOutputManager.create` → `dispose` → `Resize 0x0` →
  /// `Surface.release()` NPE in logcat, plus a reloading wallpaper.
  BackgroundControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundControllerHash();

  @$internal
  @override
  BackgroundController create() => BackgroundController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundConfigModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundConfigModel>(value),
    );
  }
}

String _$backgroundControllerHash() =>
    r'8dd0bf20fbbfc97ae557d938ee06aae39e2c0f23';

/// Background configuration and the player behind a video background.
///
/// keepAlive: the video player and its [VideoController] are created here, and
/// the background layer only *reads* this provider. As auto-dispose it was
/// disposed between reads and rebuilt on the next one, so every rebuild created
/// a new `Player`/`VideoController` and disposed the previous one — the
/// `VideoOutputManager.create` → `dispose` → `Resize 0x0` →
/// `Surface.release()` NPE in logcat, plus a reloading wallpaper.

abstract class _$BackgroundController extends $Notifier<BackgroundConfigModel> {
  BackgroundConfigModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BackgroundConfigModel, BackgroundConfigModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackgroundConfigModel, BackgroundConfigModel>,
              BackgroundConfigModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
