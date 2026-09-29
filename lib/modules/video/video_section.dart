import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// Video mode sections. The section rail lives in the home sidebar; this file
/// names them, so the mode swaps the whole navigation.
enum VideoSection { home, region, pgc, search, personal }

/// video setting asks for it, otherwise straight into the player with the
/// whole archive queued.
void openVideoArchive(BuildContext context, WidgetRef ref, MusicArchive archive) {
  final showDetail = SettingsService.to.isInitialized && SettingsService.to.videoState.showVideoDetail;
  if (showDetail) {
    VideoDetailRoute(archive).push(context);
    return;
  }
  ref.read(musicPlayerControllerProvider.notifier).playQueue(archive.tracks, startIndex: 0, audioOnly: false);
  const VideoPlayerRoute().push(context);
}

/// The card grids' shared delegate — the theme's density setting via
/// [ThemeSettingsController.cardGridDelegate].
SliverGridDelegateWithFixedCrossAxisCount defaultVideoGridDelegate(BuildContext context, WidgetRef ref) =>
    ThemeSettingsController.cardGridDelegate(context, ref);
