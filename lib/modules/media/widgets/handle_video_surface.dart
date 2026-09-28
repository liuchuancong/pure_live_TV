import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_core/media_core.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';

/// Full-bleed video surface for a [PlayerHandle], the live-play pattern (see
/// `TvVideoSurface` / `LivePlayerFacade.getVideoWidget`): the adapter's own
/// widget fills the parent, the viewport fit is applied through the media_kit
/// adapter, and an engine swap rebuilds the subtree under a fresh key so the
/// retired `Video` unmounts before the handle destroys its controller.
///
/// This replaces media_core's MediaPlayerView on the music/VOD pages: its
/// AspectRatio + LayoutBuilder + capture-boundary wrapper blows up the layout
/// pass with the DASH streams played here (a never-sized RepaintBoundary
/// asserts on every frame). The adapter's `build()` carries no such wrapper —
/// the mkv `Video` expands into whatever constraints the page's Stack gives it.
class HandleVideoSurface extends StatefulWidget {
  const HandleVideoSurface({super.key, required this.handle, this.fit});

  final PlayerHandle handle;

  /// Viewport fit, applied through [MediaKitPlayerAdapter.setVideoFit] — the
  /// same notifier the adapter's own `build()` listens to. Null leaves the
  /// adapter's current fit alone.
  final BoxFit? fit;

  @override
  State<HandleVideoSurface> createState() => _HandleVideoSurfaceState();
}

class _HandleVideoSurfaceState extends State<HandleVideoSurface> {
  StreamSubscription<void>? _backendSub;
  StreamSubscription<void>? _geometrySub;

  @override
  void initState() {
    super.initState();
    _bind();
    _applyFit();
  }

  @override
  void didUpdateWidget(HandleVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      _unbind();
      _bind();
      _applyFit();
    } else if (widget.fit != oldWidget.fit) {
      _applyFit();
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _bind() {
    _backendSub = widget.handle.backendChanges.listen((_) {
      if (!mounted) return;
      _applyFit();
      setState(() {});
    });
    // Geometry updates are the signal that the surface gained a video
    // controller — what flips `available` after an open.
    _geometrySub = widget.handle.geometryController.state.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _unbind() {
    _backendSub?.cancel();
    _backendSub = null;
    _geometrySub?.cancel();
    _geometrySub = null;
  }

  void _applyFit() {
    final BoxFit? fit = widget.fit;
    if (fit == null) return;
    final adapter = widget.handle.adapter;
    if (adapter is MediaKitPlayerAdapter) adapter.setVideoFit(fit);
  }

  @override
  Widget build(BuildContext context) {
    final adapter = widget.handle.adapter;

    // Keyed per adapter instance: on a backend swap the old `Video` unmounts
    // instead of being updated onto a foreign controller.
    final Widget video = switch (adapter) {
      final PlayerVideo output when output.available => KeyedSubtree(
        key: ValueKey('${adapter.id}_${identityHashCode(adapter)}'),
        child: output.build(),
      ),
      _ => const ColoredBox(color: Color(0xFF000000)),
    };

    return ColoredBox(color: const Color(0xFF000000), child: video);
  }
}
