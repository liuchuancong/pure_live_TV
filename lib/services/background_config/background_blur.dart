import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Applies a Gaussian blur to media backgrounds (image / video / the poster
/// frame held during playback).
///
/// Solid colours and gradients are excluded: blurring a flat surface changes
/// no pixel and still costs an offscreen pass. A [sigma] of 0 returns the child
/// unchanged, saving a saveLayer.
///
/// The blur is a per-frame GPU composite and scales with sigma; the 48 preset
/// ceiling already gives the "soft backdrop, sharp foreground" look, and past
/// it TV boxes start dropping frames.
Widget wallpaperBlurred(Widget child, double sigma) {
  if (sigma <= 0) return child;
  return ImageFiltered(
    imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
    child: child,
  );
}
