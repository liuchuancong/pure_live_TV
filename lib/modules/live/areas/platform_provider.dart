import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // Narrow watches: preferPlatform picks the initial tab, hotAreasList is
    // the platform visibility/order config — both must rebuild, while plain
    // favourite-room updates must not.
    ref.watch(favoriteRoomControllerProvider.select((s) => s.hotAreasList));
    final preferId = ref.watch(favoriteRoomControllerProvider.select((s) => s.preferPlatform));
    final sites = Sites().availableSites();
    if (sites.isEmpty) return const PlatformTabState(siteList: [], currentPlatformIndex: 0);

    final targetIndex = sites.indexWhere((s) => s.id == preferId);
    return PlatformTabState(siteList: sites, currentPlatformIndex: targetIndex == -1 ? 0 : targetIndex);
  }

  void switchPlatform(int index) {
    if (index < 0 || index >= state.siteList.length) return;
    state = PlatformTabState(siteList: state.siteList, currentPlatformIndex: index);
  }
}
