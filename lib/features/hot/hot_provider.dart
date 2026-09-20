import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hot_provider.g.dart';

class HotTabsState {
  final List<Site> sites;
  final int currentIndex;

  const HotTabsState({required this.sites, required this.currentIndex});
}

@riverpod
class HotTabs extends _$HotTabs {
  @override
  HotTabsState build() {
    // Narrow watches: these two fields feed the tabs (hotAreasList = platform
    // visibility/order), so a favourite room update no longer rebuilds — and
    // index-resets — the hot page too.
    ref.watch(favoriteRoomControllerProvider.select((s) => s.hotAreasList));
    final preferPlatform = ref.watch(favoriteRoomControllerProvider.select((s) => s.preferPlatform));
    final availableSites = Sites().availableSites();
    if (availableSites.isEmpty) {
      return const HotTabsState(sites: [], currentIndex: 0);
    }

    final pIndex = availableSites.indexWhere((e) => e.id == preferPlatform);
    final initialIndex = pIndex == -1 ? 0 : pIndex;

    return HotTabsState(sites: availableSites, currentIndex: initialIndex);
  }

  void changeTab(int index) {
    if (index >= state.sites.length || index < 0) return;
    state = HotTabsState(sites: state.sites, currentIndex: index);
  }
}
