import 'dart:ui' show ImageFilter;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/core/theme/index.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/core/utils/cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/core/consts/back_ground_source.dart';
import 'package:pure_live/core/widgets/tv_page_shell.dart';
part 'tv_scaffold_background.dart';

/// A page shell **without chrome**: no app bar, no back button, no title.
///
/// This widget used to build the app bar and own the back button for every page, which
/// made focus unpredictable: the settings shell kept ONE of these for
/// all of its pages, so the back button belonged to the shell rather than to the page it
/// was drawn on, survived every page change, and kept pulling the highlight back.
///
/// The app bar and the back button belong to the page now — see [TvPageScaffold], where
/// the page builds its own bar, owns its own node and decides what back does. Pages that
/// need no bar (the home tabs, a fullscreen page) use this one and get only what is
/// genuinely shared: the transparent page background, "a covered page offers no focus",
/// and the opening highlight on the first row.
class TvScaffold extends StatelessWidget {
  const TvScaffold({super.key, required this.child, this.openingRegion, this.openingFocus});

  final Widget child;

  /// See [TvPageShell.openingRegion] — the region the opening highlight claims.
  final GlobalKey<DpadRegionState>? openingRegion;

  /// See [TvPageShell.openingFocus] — an exact node the opening highlight
  /// claims (the home page aims it at the selected side-menu entry).
  final FocusNode? openingFocus;

  @override
  Widget build(BuildContext context) =>
      TvPageShell(openingRegion: openingRegion, openingFocus: openingFocus, child: child);
}

/// The background for the entire app: one instance, mounted below the Navigator.
class TvAppBackground extends StatelessWidget {
  const TvAppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(fit: StackFit.expand, children: [_BackgroundLayer(), _MaskLayer()]),
    );
  }
}
