import 'dart:async';
import 'package:media_core/media_core.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/player/core/playback_header_resolver.dart';

/// The low-level VOD stream mechanics shared by the music and video players.
///
/// Owns ONE [PlayerHandle] on the shared kernel and knows how to put a bilibili
/// VOD answer onto it: a DASH pair (video m4s + audio m4s) opens as a
/// [CompositeMediaSource] — the media_kit adapter joins them through mpv's
/// `audio-files` side channel — while a muxed mp4 opens as a plain
/// [PlayerSource]. A synchronous open failure (bad node, dead edge cache) rolls
/// to the answer's next backup CDN host before the handle is retired. The VOD
/// referer headers, the audio-only flag and the mpv vid-toggle that rebuilds the
/// video output against a freshly mounted surface all live here too.
///
/// Session policy — queues, play modes, progress, resume snapshots — belongs to
/// the controllers that compose this; the core only opens and transports. It is
/// deliberately NOT a Riverpod notifier so both the music and the video
/// controller can own one without sharing state.
class VodPlaybackCore {
  VodPlaybackCore({required this.configName});

  /// The [PlayerConfig] name for the handle this core creates ('music'/'video'),
  /// so the kernel's per-config tuning and logs tell the two sessions apart.
  final String configName;

  /// Adapter events (completion / error) forwarded to the owning controller,
  /// which decides what a finished or failed stream means for its session.
  void Function(PlayerAdapterEvent event)? onAdapterEvent;

  PlayerHandle? _handle;
  StreamSubscription<PlayerAdapterEvent>? _events;

  /// Bumped by the controller on every switch so a slow resolve from a
  /// superseded track cannot open its stream over the newer one.
  int _generation = 0;

  /// The stream answer behind the open handle, so a quality switch re-opens a
  /// sibling rendition without another API round-trip.
  MusicPlayUrls? currentUrls;
  String? currentBvid;

  PlayerHandle? get handle => _handle;
  Stream<PlayerTransportState>? get playbackStream => _handle?.playbackStream;
  int get generation => _generation;
  int bumpGeneration() => ++_generation;

  PlayerKernel? get _kernel => GlobalPlayerService.instance.kernel;

  /// Puts [urls] for [track] onto the handle, creating it on the shared kernel
  /// when this core has none yet, and rolls through the backup CDN hosts on a
  /// synchronous open failure. Throws when every candidate fails (the handle is
  /// retired first, so a mid-flight death cannot poison the next open).
  ///
  /// Does NOT touch controller state: the caller brackets this with its own
  /// resolving/quality updates and reads [currentUrls] for a later quality
  /// switch.
  Future<void> openUrls({
    required MusicTrack track,
    required MusicPlayUrls urls,
    required String bvid,
    required bool audioOnly,
    required double speed,
    required String preferredBackend,
  }) async {
    // Either player can be the first thing opened in a session; the live
    // bootstrap otherwise owns this call. Idempotent.
    await GlobalPlayerService.instance.initialize();
    final kernel = _kernel;
    if (kernel == null) throw Exception('player kernel not ready');
    currentUrls = urls;
    currentBvid = bvid;

    // The VOD branch of the playback header resolver: the live bilibili policy
    // with the video-page Referer.
    final headers = await PlaybackHeaderResolver.resolveVod(bvid: bvid);
    const openProtocol = SourceProtocol.https;

    final PlayerHandle handle =
        _handle ??
        await kernel.create(
          config: PlayerConfig(name: configName, autoPlay: true),
          preferredBackend: preferredBackend,
        );
    _handle = handle;

    final trackHeaders = SourceHeaders(headers);
    final sourceId = SourceId('${configName}_${track.id}_${DateTime.now().millisecondsSinceEpoch}');
    final audioUrl = urls.audioUrl;
    final dashPair = urls.isDash && audioUrl != null && audioUrl.isNotEmpty;
    // Primary CDN first, then the answer's backup hosts, in the order bilibili
    // advertised them.
    final videoCandidates = <String>[
      urls.videoUrl,
      ...urls.videoBackupUrls.where((u) => u.isNotEmpty),
    ];
    Object? lastError;
    var opened = false;
    for (final videoUrl in videoCandidates) {
      try {
        if (dashPair) {
          await handle.openMedia(
            CompositeMediaSource(
              videoTracks: [
                MediaTrack(uri: Uri.parse(videoUrl), kind: MediaTrackType.video, headers: trackHeaders),
              ],
              audioTracks: [
                MediaTrack(uri: Uri.parse(audioUrl), kind: MediaTrackType.audio, headers: trackHeaders),
              ],
            ),
            autoPlay: true,
          );
        } else {
          await handle.open(
            PlayerSource(
              id: sourceId,
              uri: Uri.parse(videoUrl),
              protocol: openProtocol,
              headers: trackHeaders,
              title: track.title,
            ),
            autoPlay: true,
          );
        }
        opened = true;
        break;
      } catch (error) {
        lastError = error;
      }
    }
    if (!opened) {
      await releaseHandle();
      throw lastError ?? Exception('playurl open failed');
    }

    try {
      await handle.setAudioOnly(audioOnly);
    } catch (_) {}

    // A picture session may have opened before the Flutter surface was live, so
    // mpv built its video output against a black texture. Toggling vid off → on
    // rebuilds the output against the surface that is now mounted.
    if (!audioOnly) {
      try {
        await handle.setAudioOnly(true);
        await handle.setAudioOnly(false);
      } catch (_) {}
    }

    _events?.cancel();
    _events = handle.adapterEvents.listen((event) => onAdapterEvent?.call(event));
    // The rate persists across track switches: a viewer at 1.5x keeps 1.5x on
    // the next episode.
    if (speed != 1.0) {
      await ignoreCancelled(() => handle.setRate(speed));
    }

    // Cloud history heartbeat per track start (the bmsc behaviour): the
    // bilibili history page then shows what was played. Silent when logged out
    // or the report fails.
    if (track.archive.aid > 0) {
      BilibiliUgcApi.instance
          .reportHistory(aid: track.archive.aid, cid: track.part.cid, progress: 0, bvid: track.archive.bvid)
          .catchError((Object _) {});
    }
  }

  Future<void> releaseHandle() async {
    _events?.cancel();
    _events = null;
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    final kernel = _kernel;
    if (kernel == null) return;
    try {
      await kernel.release(handle.id);
    } catch (_) {
      // A handle that already fell over must not take the next track down.
    }
  }

  /// Waits — bounded — for a freshly opened backend to prove it is seekable,
  /// then seeks. better_player initializes asynchronously and drops a seek that
  /// lands before its first duration report; mpv accepts one only once the
  /// demuxer is up.
  Future<void> restorePosition(Duration position) async {
    if (position <= Duration.zero) return;
    await ignoreCancelled(() async {
      final target = _handle;
      if (target == null) return;
      for (var i = 0; i < 40; i++) {
        if (target.duration > Duration.zero || target.isPlaying) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await target.seek(position);
    });
  }

  /// A transport operation that loses to a newer one — another seek, a track
  /// switch, a stop — is cancelled by media_core by design: the player has
  /// already moved on, so the superseded one must not surface as an error.
  static Future<void> ignoreCancelled(Future<void> Function() operation) async {
    try {
      await operation();
    } on OperationCancelledException {
      // Superseded — the newer operation owns the transport now.
    }
  }
}
