import 'package:pure_live/core/sites/sites.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/services/history_settings/history_model.dart';
import 'package:pure_live/services/history_settings/history_controller.dart';

part 'history_page_provider.g.dart';

class HistoryPageState {
  final int tabSiteIndex;
  final List<LiveRoom> rooms;

  const HistoryPageState({this.tabSiteIndex = 0, this.rooms = const []});

  HistoryPageState copyWith({int? tabSiteIndex, List<LiveRoom>? rooms}) {
    return HistoryPageState(tabSiteIndex: tabSiteIndex ?? this.tabSiteIndex, rooms: rooms ?? this.rooms);
  }
}

@riverpod
class HistoryPageNotifier extends _$HistoryPageNotifier {
  @override
  HistoryPageState build() {
    final historyState = ref.watch(historyControllerProvider);
    return _syncAndFilter(const HistoryPageState(), historyState);
  }

  void changeSiteTab(int index) {
    final historyState = ref.read(historyControllerProvider);
    state = _syncAndFilter(state.copyWith(tabSiteIndex: index), historyState);
  }

  HistoryPageState _syncAndFilter(HistoryPageState currentState, HistoryModel historyState) {
    final currentAvailableSites = Sites().availableSites(containsAll: true);
    if (currentState.tabSiteIndex < 0 || currentState.tabSiteIndex >= currentAvailableSites.length) {
      return currentState.copyWith(rooms: []);
    }

    final activeSite = currentAvailableSites[currentState.tabSiteIndex];
    List<LiveRoom> historyRooms = List<LiveRoom>.from(historyState.historyRooms);

    if (activeSite.id != Sites.allSite) {
      historyRooms = historyRooms.where((room) => room.platform.toUpperCase() == activeSite.id.toUpperCase()).toList();
    }

    return currentState.copyWith(tabSiteIndex: currentState.tabSiteIndex, rooms: historyRooms);
  }
}
