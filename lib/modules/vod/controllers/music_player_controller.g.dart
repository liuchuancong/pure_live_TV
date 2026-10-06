// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The music-mode player: a track queue, the advance rules and the listening
/// extras (play-later strip, sleep timer, resume snapshot, recently played).
///
/// Playback runs on its OWN [PlayerHandle] through [VodPlaybackCore], separate
/// from the video player's handle, so a video never replaces the music queue
/// and never reads back as the current song. Deliberately not the live facade:
/// that path is tuned for non-seekable streams and lease renewal, while VOD
/// needs the seek, position and duration the raw handle already carries.

@ProviderFor(MusicPlayerController)
final musicPlayerControllerProvider = MusicPlayerControllerProvider._();

/// The music-mode player: a track queue, the advance rules and the listening
/// extras (play-later strip, sleep timer, resume snapshot, recently played).
///
/// Playback runs on its OWN [PlayerHandle] through [VodPlaybackCore], separate
/// from the video player's handle, so a video never replaces the music queue
/// and never reads back as the current song. Deliberately not the live facade:
/// that path is tuned for non-seekable streams and lease renewal, while VOD
/// needs the seek, position and duration the raw handle already carries.
final class MusicPlayerControllerProvider
    extends $NotifierProvider<MusicPlayerController, MusicPlayerState> {
  /// The music-mode player: a track queue, the advance rules and the listening
  /// extras (play-later strip, sleep timer, resume snapshot, recently played).
  ///
  /// Playback runs on its OWN [PlayerHandle] through [VodPlaybackCore], separate
  /// from the video player's handle, so a video never replaces the music queue
  /// and never reads back as the current song. Deliberately not the live facade:
  /// that path is tuned for non-seekable streams and lease renewal, while VOD
  /// needs the seek, position and duration the raw handle already carries.
  MusicPlayerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicPlayerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicPlayerControllerHash();

  @$internal
  @override
  MusicPlayerController create() => MusicPlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicPlayerState>(value),
    );
  }
}

String _$musicPlayerControllerHash() =>
    r'782e283fceb95d627b7166545ebb8552522de41b';

/// The music-mode player: a track queue, the advance rules and the listening
/// extras (play-later strip, sleep timer, resume snapshot, recently played).
///
/// Playback runs on its OWN [PlayerHandle] through [VodPlaybackCore], separate
/// from the video player's handle, so a video never replaces the music queue
/// and never reads back as the current song. Deliberately not the live facade:
/// that path is tuned for non-seekable streams and lease renewal, while VOD
/// needs the seek, position and duration the raw handle already carries.

abstract class _$MusicPlayerController extends $Notifier<MusicPlayerState> {
  MusicPlayerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MusicPlayerState, MusicPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MusicPlayerState, MusicPlayerState>,
              MusicPlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
