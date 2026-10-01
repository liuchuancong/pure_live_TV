// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// opens at (quality, speed, detail-first) and which section the mode lands on.
/// Music is deliberately untouched — this controller is only read from the
/// video surfaces.

@ProviderFor(VideoSettingsController)
final videoSettingsControllerProvider = VideoSettingsControllerProvider._();

/// opens at (quality, speed, detail-first) and which section the mode lands on.
/// Music is deliberately untouched — this controller is only read from the
/// video surfaces.
final class VideoSettingsControllerProvider
    extends $NotifierProvider<VideoSettingsController, VideoSettingsModel> {
  /// opens at (quality, speed, detail-first) and which section the mode lands on.
  /// Music is deliberately untouched — this controller is only read from the
  /// video surfaces.
  VideoSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoSettingsControllerHash();

  @$internal
  @override
  VideoSettingsController create() => VideoSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoSettingsModel>(value),
    );
  }
}

String _$videoSettingsControllerHash() =>
    r'fedffb820733515f159b87cdb9691aaa908a48ea';

/// opens at (quality, speed, detail-first) and which section the mode lands on.
/// Music is deliberately untouched — this controller is only read from the
/// video surfaces.

abstract class _$VideoSettingsController extends $Notifier<VideoSettingsModel> {
  VideoSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VideoSettingsModel, VideoSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VideoSettingsModel, VideoSettingsModel>,
              VideoSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
