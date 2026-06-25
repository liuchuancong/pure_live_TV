import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';
import 'package:pure_live/services/favorite_settings/favorite_room_controller.dart';

part 'favorite_areas_provider.g.dart';

class FavoriteAreasState {
  final int tabSiteIndex;
  final List<LiveArea> areas;

  const FavoriteAreasState({this.tabSiteIndex = 0, this.areas = const []});

  FavoriteAreasState copyWith({int? tabSiteIndex, List<LiveArea>? areas}) {
    return FavoriteAreasState(tabSiteIndex: tabSiteIndex ?? this.tabSiteIndex, areas: areas ?? this.areas);
  }
}

@riverpod
class FavoriteAreasNotifier extends _$FavoriteAreasNotifier {
  @override
  FavoriteAreasState build() {
    ref.watch(favoriteRoomControllerProvider);
    return _syncAndFilter(const FavoriteAreasState());
  }

  void changeSiteTab(int index) {
    state = _syncAndFilter(state.copyWith(tabSiteIndex: index));
  }

  FavoriteAreasState _syncAndFilter(FavoriteAreasState currentState) {
    final currentAvailableSites = Sites().availableSites(containsAll: true);
    if (currentState.tabSiteIndex < 0 || currentState.tabSiteIndex >= currentAvailableSites.length) {
      return currentState.copyWith(areas: []);
    }

    final activeSite = currentAvailableSites[currentState.tabSiteIndex];
    final favState = SettingsService.to.favState;
    List<LiveArea> sourceAreas = List<LiveArea>.from(favState.favoriteAreas);

    if (activeSite.id != Sites.allSite) {
      sourceAreas = sourceAreas.where((area) => area.platform.toUpperCase() == activeSite.id.toUpperCase()).toList();
    }

    return currentState.copyWith(areas: sourceAreas);
  }
}
