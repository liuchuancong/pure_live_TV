import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/services/settings/settings.dart';
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
    final availableSites = Sites().availableSites();
    if (availableSites.isEmpty) {
      return const HotTabsState(sites: [], currentIndex: 0);
    }

    final preferPlatform = SettingsService.to.favState.preferPlatform;
    final pIndex = availableSites.indexWhere((e) => e.id == preferPlatform);
    final initialIndex = pIndex == -1 ? 0 : pIndex;

    return HotTabsState(sites: availableSites, currentIndex: initialIndex);
  }

  void changeTab(int index) {
    if (index >= state.sites.length || index < 0) return;
    state = HotTabsState(sites: state.sites, currentIndex: index);
  }
}
