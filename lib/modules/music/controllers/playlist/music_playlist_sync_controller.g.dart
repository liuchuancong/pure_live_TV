// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_playlist_sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sync engine behind the synced playlists (bmsc's fav-list caching):
/// bilibili fav folders pulled down into music-module Hive keys so the
/// playlists open offline and survive restarts. Video never reads these keys —
/// the modules' local data stay strictly separated.
///
/// "excluded parts" feature.

@ProviderFor(MusicPlaylistSyncController)
final musicPlaylistSyncControllerProvider =
    MusicPlaylistSyncControllerProvider._();

/// The sync engine behind the synced playlists (bmsc's fav-list caching):
/// bilibili fav folders pulled down into music-module Hive keys so the
/// playlists open offline and survive restarts. Video never reads these keys —
/// the modules' local data stay strictly separated.
///
/// "excluded parts" feature.
final class MusicPlaylistSyncControllerProvider
    extends
        $NotifierProvider<MusicPlaylistSyncController, MusicPlaylistSyncState> {
  /// The sync engine behind the synced playlists (bmsc's fav-list caching):
  /// bilibili fav folders pulled down into music-module Hive keys so the
  /// playlists open offline and survive restarts. Video never reads these keys —
  /// the modules' local data stay strictly separated.
  ///
  /// "excluded parts" feature.
  MusicPlaylistSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicPlaylistSyncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicPlaylistSyncControllerHash();

  @$internal
  @override
  MusicPlaylistSyncController create() => MusicPlaylistSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicPlaylistSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicPlaylistSyncState>(value),
    );
  }
}

String _$musicPlaylistSyncControllerHash() =>
    r'5907648aa59eab4142a70ca7c8f29bd4e4a8fc37';

/// The sync engine behind the synced playlists (bmsc's fav-list caching):
/// bilibili fav folders pulled down into music-module Hive keys so the
/// playlists open offline and survive restarts. Video never reads these keys —
/// the modules' local data stay strictly separated.
///
/// "excluded parts" feature.

abstract class _$MusicPlaylistSyncController
    extends $Notifier<MusicPlaylistSyncState> {
  MusicPlaylistSyncState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<MusicPlaylistSyncState, MusicPlaylistSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MusicPlaylistSyncState, MusicPlaylistSyncState>,
              MusicPlaylistSyncState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
