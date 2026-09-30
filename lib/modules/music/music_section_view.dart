import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/modules/music/music_section.dart';
import 'package:pure_live/modules/vod/pages/ugc_dynamics_page.dart';
import 'package:pure_live/modules/music/pages/music_follow_pane.dart';
import 'package:pure_live/modules/music/pages/mine/music_recents_page.dart';
import 'package:pure_live/modules/music/pages/search/music_search_page.dart';
import 'package:pure_live/modules/music/pages/discover/music_daily_page.dart';
import 'package:pure_live/modules/music/pages/mine/music_follow_section.dart';
import 'package:pure_live/modules/music/pages/discover/music_ranking_page.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_fav_folders_page.dart';
import 'package:pure_live/modules/music/pages/discover/music_cloud_history_page.dart';
import 'package:pure_live/modules/music/pages/playback/music_now_playing_queue_page.dart';

/// Content of one music section. The section rail lives in the home sidebar;
/// login is enforced by the home shell's BilibiliLoginGate, not here.
///
/// A multi-section group carries the newBV-style top tab bar: it names the
/// group's sections and swaps the content below; single-section groups
///
/// With the refresh settings' keep-alive switch on (the live home's switch),
/// every section's page is built at most once per run and the group renders
/// an IndexedStack over them — switching tabs re-shows the cached page
/// instead of refetching it. Off, sections swap in place and a switch
/// rebuilds the page, as before.
class MusicSectionView extends ConsumerStatefulWidget {
  const MusicSectionView({super.key, required this.section});

  final MusicSection section;

  @override
  ConsumerState<MusicSectionView> createState() => _MusicSectionViewState();
}

class _MusicSectionViewState extends ConsumerState<MusicSectionView> {
  /// The once-per-run children, keyed by section. Lived in the widget tree via
  /// the IndexedStack below, a page keeps its scroll position and its fetched
  /// data across tab switches.
  final Map<MusicSection, Widget> _children = {};

  Widget _buildSection(MusicSection section) => switch (section) {
    MusicSection.favorites => const MusicFollowSection(key: ValueKey('music_favorites')),
    MusicSection.daily => const MusicDailyPage(key: ValueKey('music_daily')),
    MusicSection.recents => const MusicRecentsPage(key: ValueKey('music_recents')),
    MusicSection.playlists => const MusicFavFoldersPage(key: ValueKey('music_playlists')),
    MusicSection.dynamics => const UgcDynamicsPage(key: ValueKey('music_dynamics')),
    MusicSection.history => const MusicCloudHistoryPage(key: ValueKey('music_history')),
    MusicSection.followedUps => const MusicFollowPane(key: ValueKey('music_followed_ups')),
    MusicSection.ranking => const MusicRankingPage(key: ValueKey('music_ranking')),
    MusicSection.search => const MusicSearchPage(key: ValueKey('music_search')),
    MusicSection.nowPlaying => const MusicNowPlayingQueuePage(key: ValueKey('music_now_playing')),
  };

  Widget _childFor(MusicSection section) => _children.putIfAbsent(section, () => _buildSection(section));

  @override
  Widget build(BuildContext context) {
    final group = kMusicRailGroups[musicRailIndexFor(widget.section)];
    final keepAlive = ref.watch(refreshConfigControllerProvider.select((s) => s.homeKeepAlive));

    final List<Widget> Function() column;
    if (keepAlive && group.length > 1) {
      column = () => [
        Padding(
          padding: EdgeInsets.fromLTRB(24.ts(context), 12.ts(context), 24.ts(context), 0),
          child: TvTabBar(
            tabs: [for (final s in group) TvTabItemData(title: musicSectionTabLabel(s))],
            currentIndex: group.indexOf(widget.section),
            showRefreshLine: false,
            onTabChange: (index) => ref.read(musicSectionIndexProvider.notifier).change(group[index].index),
          ),
        ),
        Expanded(
          // Offstage group members keep their state: the dynamic page's grid
          // and the ranking page's rows survive a tab hop untouched.
          child: IndexedStack(index: group.indexOf(widget.section), children: [for (final s in group) _childFor(s)]),
        ),
      ];
    } else {
      // Keep-alive off (or a single-section group): swap in place, rebuild on
      // every switch — the pre-cache behaviour the switch exists to choose.
      final content = keepAlive ? _childFor(widget.section) : _buildSection(widget.section);
      column = () => [
        if (group.length > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(24.ts(context), 12.ts(context), 24.ts(context), 0),
            child: TvTabBar(
              tabs: [for (final s in group) TvTabItemData(title: musicSectionTabLabel(s))],
              currentIndex: group.indexOf(widget.section),
              showRefreshLine: false,
              onTabChange: (index) => ref.read(musicSectionIndexProvider.notifier).change(group[index].index),
            ),
          ),
        Expanded(child: content),
      ];
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: column());
  }
}
