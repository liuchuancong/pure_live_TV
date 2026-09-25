import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/utils/githup_mirror.dart';

/// Picks the address a playlist is actually fetched from.
///
/// A GitHub-hosted playlist is raced across the [GitHubMirror] pool, because
/// the raw origin is blocked or throttled on mainland networks; every other
/// host is used as-is.
///
/// Speed alone is not enough to win: several mirrors answer a request with a
/// landing page while returning 200, so a candidate only counts when its body
/// really starts like a playlist. A bare `findFastestUrl` race would hand such
/// a proxy to the importer as the "fast" source. Mirrors rotate too, so the
/// result is never persisted — the stored provider keeps the canonical address
/// and re-races on every sync.
class PlaylistSourceResolver {
  const PlaylistSourceResolver._();

  /// A source that cannot deliver a playlist inside this window is no better
  /// than a dead one, and the caller is usually blocking a page build.
  static const Duration _raceWindow = Duration(seconds: 15);

  /// Enough of the body to recognise the format, and small enough that a
  /// mirror which ignores Range still costs almost nothing.
  static const String _probeRange = 'bytes=0-2047';

  /// The address to fetch [url] from, or [url] itself when nothing better
  /// answers. Non-GitHub addresses are never probed.
  static Future<String> resolve(String url, {Map<String, String>? headers}) async {
    final candidates = GitHubMirror.candidatesFor(url);
    if (candidates.length < 2) return url;
    final winner = await _raceForPlaylist(candidates, headers);
    if (winner == null) {
      debugPrint('No mirror served a playlist, falling back to origin: $url');
      return url;
    }
    debugPrint('Playlist source resolved to: $winner');
    return winner;
  }

  /// Resolves with the first candidate whose body looks like a playlist, or
  /// null when the pool fails or outlives [_raceWindow].
  static Future<String?> _raceForPlaylist(List<String> candidates, Map<String, String>? headers) async {
    final completer = Completer<String?>();
    final timer = Timer(_raceWindow, () => _finish(completer, null));
    for (final candidate in candidates) {
      unawaited(
        Future(() async {
          if (await _servesPlaylist(candidate, headers)) _finish(completer, candidate);
        }),
      );
    }
    final winner = await completer.future;
    timer.cancel();
    return winner;
  }

  static void _finish(Completer<String?> completer, String? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  /// Whether [url] answers with something both parsers accept.
  static Future<bool> _servesPlaylist(String url, Map<String, String>? headers) async {
    try {
      final body = (await HttpClient.instance.getText(url, header: {...?headers, 'range': _probeRange})).trimLeft();
      return body.startsWith('#EXTM3U') || body.contains(',#genre#');
    } catch (_) {
      // Another mirror may still answer.
      return false;
    }
  }
}
