// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The video-mode player: its own VOD [PlayerHandle] on the shared kernel, a
/// strictly sequential part/episode list, and the picture-session extras
/// (quality, rate). Deliberately separate from [MusicPlayerController] so a
/// video never replaces the music queue, never overwrites the music resume
/// snapshot, and never reads back as the current song.
///
/// Opening a video suspends the music and live sessions (they keep their state,
/// drop the handle); the page's own [stop] on exit tears the video session down.

@ProviderFor(VideoPlayerController)
final videoPlayerControllerProvider = VideoPlayerControllerProvider._();

/// The video-mode player: its own VOD [PlayerHandle] on the shared kernel, a
/// strictly sequential part/episode list, and the picture-session extras
/// (quality, rate). Deliberately separate from [MusicPlayerController] so a
/// video never replaces the music queue, never overwrites the music resume
/// snapshot, and never reads back as the current song.
///
/// Opening a video suspends the music and live sessions (they keep their state,
/// drop the handle); the page's own [stop] on exit tears the video session down.
final class VideoPlayerControllerProvider
    extends $NotifierProvider<VideoPlayerController, VideoPlayerState> {
  /// The video-mode player: its own VOD [PlayerHandle] on the shared kernel, a
  /// strictly sequential part/episode list, and the picture-session extras
  /// (quality, rate). Deliberately separate from [MusicPlayerController] so a
  /// video never replaces the music queue, never overwrites the music resume
  /// snapshot, and never reads back as the current song.
  ///
  /// Opening a video suspends the music and live sessions (they keep their state,
  /// drop the handle); the page's own [stop] on exit tears the video session down.
  VideoPlayerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoPlayerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoPlayerControllerHash();

  @$internal
  @override
  VideoPlayerController create() => VideoPlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoPlayerState>(value),
    );
  }
}

String _$videoPlayerControllerHash() =>
    r'b1c4a932a79e98cea39bcad8caa9207228a7a3e8';

/// The video-mode player: its own VOD [PlayerHandle] on the shared kernel, a
/// strictly sequential part/episode list, and the picture-session extras
/// (quality, rate). Deliberately separate from [MusicPlayerController] so a
/// video never replaces the music queue, never overwrites the music resume
/// snapshot, and never reads back as the current song.
///
/// Opening a video suspends the music and live sessions (they keep their state,
/// drop the handle); the page's own [stop] on exit tears the video session down.

abstract class _$VideoPlayerController extends $Notifier<VideoPlayerState> {
  VideoPlayerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VideoPlayerState, VideoPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VideoPlayerState, VideoPlayerState>,
              VideoPlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
