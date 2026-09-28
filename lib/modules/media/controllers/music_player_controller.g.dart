// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The music-mode player: one VOD [PlayerHandle] on the shared kernel, a track
/// queue and the advance rules.
///
/// Deliberately *not* the live facade: that path is tuned for non-seekable
/// streams and lease renewal. VOD needs seek, position and duration, which the
/// raw handle already carries. The handle is created per track and released on
/// switch, so the mpv `audio-file` input (which attaches the DASH audio stream
/// to the video-only primary) is set per track without touching the shared
/// engine registrations.

@ProviderFor(MusicPlayerController)
final musicPlayerControllerProvider = MusicPlayerControllerProvider._();

/// The music-mode player: one VOD [PlayerHandle] on the shared kernel, a track
/// queue and the advance rules.
///
/// Deliberately *not* the live facade: that path is tuned for non-seekable
/// streams and lease renewal. VOD needs seek, position and duration, which the
/// raw handle already carries. The handle is created per track and released on
/// switch, so the mpv `audio-file` input (which attaches the DASH audio stream
/// to the video-only primary) is set per track without touching the shared
/// engine registrations.
final class MusicPlayerControllerProvider
    extends $NotifierProvider<MusicPlayerController, MusicPlayerState> {
  /// The music-mode player: one VOD [PlayerHandle] on the shared kernel, a track
  /// queue and the advance rules.
  ///
  /// Deliberately *not* the live facade: that path is tuned for non-seekable
  /// streams and lease renewal. VOD needs seek, position and duration, which the
  /// raw handle already carries. The handle is created per track and released on
  /// switch, so the mpv `audio-file` input (which attaches the DASH audio stream
  /// to the video-only primary) is set per track without touching the shared
  /// engine registrations.
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
    r'6836b7e16393432f2fe6f4320a1354dc42013697';

/// The music-mode player: one VOD [PlayerHandle] on the shared kernel, a track
/// queue and the advance rules.
///
/// Deliberately *not* the live facade: that path is tuned for non-seekable
/// streams and lease renewal. VOD needs seek, position and duration, which the
/// raw handle already carries. The handle is created per track and released on
/// switch, so the mpv `audio-file` input (which attaches the DASH audio stream
/// to the video-only primary) is set per track without touching the shared
/// engine registrations.

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
