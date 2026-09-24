import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Keeps the video wallpaper in step with the player page's presence on the
/// navigation stack.
///
/// The route stack — not the engine — is the source of truth for "is the
/// player page on screen": ExoPlayer reports play/pause at buffer frequency,
/// and forwarding those to the wallpaper layer used to tear the background
/// decoder down and rebuild it on every tick. A push/pop is a real user
/// action; a buffer flip is not.
///
/// Install by passing an instance to `GoRouter(observers: [...])`.
class WallpaperRouteObserver extends NavigatorObserver {
  /// Route name (not path) of the player page.
  ///
  /// Must match the `name:` of the `GoRoute` that hosts the page.
  static const String livePlayRouteName = AppRoutes.kLivePlayName;

  bool _suspended = false;

  bool _isLiveRoute(Route<dynamic>? route) => route?.settings.name == livePlayRouteName;

  void _sync(bool suspended) {
    if (_suspended == suspended) return;
    _suspended = suspended;
    try {
      unawaited(SettingsService.to.bg.setPlaybackActive(suspended));
    } catch (_) {
      // SettingsService not ready (early boot / tests): leave the wallpaper
      // as it is.
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isLiveRoute(route)) _sync(true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isLiveRoute(route)) _sync(false);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isLiveRoute(route)) _sync(false);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // Channel switching uses replace, so both routes are the player page:
    // `_sync(true)` is a no-op and the wallpaper stays suspended across the
    // handover instead of flickering.
    if (_isLiveRoute(newRoute) || _isLiveRoute(oldRoute)) {
      _sync(_isLiveRoute(newRoute));
    }
  }
}
