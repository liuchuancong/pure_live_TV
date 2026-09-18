import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_provider.g.dart';

class PlatformTabState {
  final List<Site> siteList;
  final int currentPlatformIndex;
  const PlatformTabState({required this.siteList, required this.currentPlatformIndex});
}

@riverpod
class PlatformTab extends _$PlatformTab {
  @override
  PlatformTabState build() {
    // Whole favorites state: hotAreasList (platform display config) feeds
    // availableSites, and watching only preferPlatform left stale tabs.
    final favState = ref.watch(favoriteRoomControllerProvider);
    final sites = Sites().availableSites();
    if (sites.isEmpty) return const PlatformTabState(siteList: [], currentPlatformIndex: 0);
    final preferId = favState.preferPlatform;
    final targetIndex = sites.indexWhere((s) => s.id == preferId);
    return PlatformTabState(siteList: sites, currentPlatformIndex: targetIndex == -1 ? 0 : targetIndex);
  }

  void switchPlatform(int index) {
    if (index < 0 || index >= state.siteList.length) return;
    state = PlatformTabState(siteList: state.siteList, currentPlatformIndex: index);
  }
}
