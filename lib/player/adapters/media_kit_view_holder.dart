import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

/// Binds a media_kit [Video] to a [VideoController] without the
/// widget owning the adapter lifecycle.
///
/// The surface layer watches [fitNotifier] for fit changes.
final class MediaKitViewHolder {
  /// Creates the holder.
  MediaKitViewHolder();

  /// Notifies on every fit change.
  final ValueNotifier<BoxFit> fitNotifier = ValueNotifier<BoxFit>(BoxFit.contain);

  /// Updates the fit and notifies listeners.
  // ignore: use_setters_to_change_properties
  void updateFit(BoxFit value) {
    fitNotifier.value = value;
  }

  /// Builds the video view for [controller].
  Widget build(mkv.VideoController controller) {
    return ValueListenableBuilder<BoxFit>(
      valueListenable: fitNotifier,
      builder: (context, fit, _) {
        return mkv.Video(
          controller: controller,
          controls: mkv.NoVideoControls,
          fit: fit,
          // Lifecycle pauses are owned by the app's coordinator;
          // letting Video apply its own policy double-paused live
          // rooms on Home/lock.
          pauseUponEnteringBackgroundMode: false,
          resumeUponEnteringForegroundMode: false,
        );
      },
    );
  }

  /// Releases the holder.
  void dispose() {
    fitNotifier.dispose();
  }
}
