// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_progress_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The video module's local watch-progress store, newBV's 已播进度条: every
/// part that opens reports its position, cards render the progress bar, and a
/// reopened archive resumes from where it stopped.
///
/// Persisted in the video-module Hive key `videoWatchProgress` — music keeps
/// its own keys and the two libraries never touch.

@ProviderFor(VideoProgressController)
final videoProgressControllerProvider = VideoProgressControllerProvider._();

/// The video module's local watch-progress store, newBV's 已播进度条: every
/// part that opens reports its position, cards render the progress bar, and a
/// reopened archive resumes from where it stopped.
///
/// Persisted in the video-module Hive key `videoWatchProgress` — music keeps
/// its own keys and the two libraries never touch.
final class VideoProgressControllerProvider
    extends $NotifierProvider<VideoProgressController, VideoProgressState> {
  /// The video module's local watch-progress store, newBV's 已播进度条: every
  /// part that opens reports its position, cards render the progress bar, and a
  /// reopened archive resumes from where it stopped.
  ///
  /// Persisted in the video-module Hive key `videoWatchProgress` — music keeps
  /// its own keys and the two libraries never touch.
  VideoProgressControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoProgressControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoProgressControllerHash();

  @$internal
  @override
  VideoProgressController create() => VideoProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoProgressState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoProgressState>(value),
    );
  }
}

String _$videoProgressControllerHash() =>
    r'885c56e91b6ca39ba2c0443646f975187f8b000c';

/// The video module's local watch-progress store, newBV's 已播进度条: every
/// part that opens reports its position, cards render the progress bar, and a
/// reopened archive resumes from where it stopped.
///
/// Persisted in the video-module Hive key `videoWatchProgress` — music keeps
/// its own keys and the two libraries never touch.

abstract class _$VideoProgressController extends $Notifier<VideoProgressState> {
  VideoProgressState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VideoProgressState, VideoProgressState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VideoProgressState, VideoProgressState>,
              VideoProgressState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
