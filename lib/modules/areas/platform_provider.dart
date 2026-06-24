import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/services/settings/settings.dart';
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
    final sites = Sites().availableSites();
    if (sites.isEmpty) return const PlatformTabState(siteList: [], currentPlatformIndex: 0);
    final preferId = SettingsService.to.favState.preferPlatform;
    final targetIndex = sites.indexWhere((s) => s.id == preferId);
    return PlatformTabState(siteList: sites, currentPlatformIndex: targetIndex == -1 ? 0 : targetIndex);
  }

  void switchPlatform(int index) {
    if (index < 0 || index >= state.siteList.length) return;
    state = PlatformTabState(siteList: state.siteList, currentPlatformIndex: index);
  }
}
