import 'package:flv_lzc/fijkplayer.dart';
import 'package:flutter/material.dart';

import '../utils/fijk_helper.dart';

/// Binds an [FijkView] to a [FijkPlayer] without the widget owning
/// the adapter lifecycle.
///
/// The surface layer watches [fitNotifier] and rebuilds the view;
/// the adapter pushes fit changes through [fit]. Rebuilding (not
/// mutating) is what keeps the texture geometry stable on TV
/// devices while decoder dimensions settle.
final class FijkViewHolder {
  /// Creates the holder.
  FijkViewHolder();

  /// The fit the view renders with.
  BoxFit fit = BoxFit.contain;

  /// Notifies on every fit change.
  final ValueNotifier<BoxFit> fitNotifier = ValueNotifier<BoxFit>(BoxFit.contain);

  /// Sets the fit and notifies listeners.
  // ignore: use_setters_to_change_properties
  void updateFit(BoxFit value) {
    fit = value;
    fitNotifier.value = value;
  }

  /// Builds the video view for [player].
  Widget build(FijkPlayer player) {
    return ValueListenableBuilder<BoxFit>(
      valueListenable: fitNotifier,
      builder: (context, fit, _) {
        return FijkView(
          player: player,
          fit: FijkHelper.getIjkBoxFit(fit),
          fs: false,
          color: Colors.black,
          panelBuilder: (FijkPlayer fijkPlayer, FijkData fijkData, BuildContext context, Size viewSize, Rect texturePos) {
            return const SizedBox();
          },
        );
      },
    );
  }

  /// Releases the holder.
  void dispose() {
    fitNotifier.dispose();
  }
}
