import 'package:flutter/material.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

/// Puts a list back on the track that is playing when the player page closes:
/// the row scrolls into view and takes the focus, so returning reads as "here
/// is what is on" instead of leaving the viewer wherever the list happened to
/// be.
///
/// One instance per list page, held by that page's state. Rows register their
/// context as they build ([bindRow]) — a lazy list only knows the rows it has
/// built, which covers the usual return (the playing track was started from
/// this list). When the playing row sits outside the built window, a
/// uniform-row estimate jumps first and the row's own reveal fine-tunes.
class MusicListReveal {
  final Map<String, FocusNode> _nodes = {};
  final Map<String, BuildContext> _contexts = {};
  bool _disposed = false;

  FocusNode nodeFor(MusicTrack track) => _nodes.putIfAbsent(track.id, FocusNode.new);

  /// The list row calls this on every build with its own context.
  void bindRow(MusicTrack track, BuildContext context) {
    if (_disposed) return;
    _contexts[track.id] = context;
  }

  void dispose() {
    _disposed = true;
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
    _contexts.clear();
  }

  /// The list index of the playing track — the same bvid+page identity the
  /// playing badge compares.
  static int indexOf(List<MusicTrack> tracks, MusicTrack? current) {
    if (current == null) return -1;
    return tracks.indexWhere(
      (t) => t.archive.bvid == current.archive.bvid && t.part.page == current.part.page,
    );
  }

  /// Scrolls the playing track into view and focuses its row. Call after the
  /// player route has been popped, with the list the viewer is looking at.
  void reveal(BuildContext context, List<MusicTrack> tracks, MusicTrack? current, {double rowGap = 4.0}) {
    final at = indexOf(tracks, current);
    if (at < 0) return;
    final id = tracks[at].id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !context.mounted) return;
      var row = _contexts[id];
      if (row == null || !row.mounted) {
        _jumpEstimate(context, tracks, at, rowGap);
        row = _contexts[id];
      }
      _revealRow(row, id);
    });
  }

  void _revealRow(BuildContext? row, String id) {
    if (row != null && row.mounted) {
      Scrollable.ensureVisible(
        row,
        alignment: 0.35,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    _nodes[id]?.requestFocus();
  }

  /// The playing row is not built: measure a built row of this list and jump
  /// so the target enters the window — its ensureVisible then runs next frame.
  void _jumpEstimate(BuildContext context, List<MusicTrack> tracks, int at, double rowGap) {
    BuildContext? sample;
    for (final candidate in _contexts.values) {
      if (candidate.mounted) {
        sample = candidate;
        break;
      }
    }
    final scrollable = Scrollable.maybeOf(context);
    if (sample == null || scrollable == null) return;
    final box = sample.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final double extent = box.size.height + rowGap;
    final double target = (at * extent - scrollable.position.viewportDimension * 0.35)
        .clamp(0.0, scrollable.position.maxScrollExtent);
    scrollable.position.jumpTo(target);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _revealRow(_contexts[tracks[at].id], tracks[at].id);
    });
  }
}
