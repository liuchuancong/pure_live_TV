import 'package:pure_live/core/sites/sites.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';

part 'tv_search_provider.g.dart';

class TvSearchState {
  final int tabSiteIndex;
  final String keyword;
  final List<LiveRoom> rawResults;
  final List<LiveRoom> searchResults;
  final bool isLoading;

  const TvSearchState({
    this.tabSiteIndex = 0,
    this.keyword = '',
    this.rawResults = const [],
    this.searchResults = const [],
    this.isLoading = false,
  });

  TvSearchState copyWith({
    int? tabSiteIndex,
    String? keyword,
    List<LiveRoom>? rawResults,
    List<LiveRoom>? searchResults,
    bool? isLoading,
  }) {
    return TvSearchState(
      tabSiteIndex: tabSiteIndex ?? this.tabSiteIndex,
      keyword: keyword ?? this.keyword,
      rawResults: rawResults ?? this.rawResults,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(name: 'tvSearchNotifierProvider')
class TvSearchNotifier extends _$TvSearchNotifier {
  @override
  TvSearchState build() => const TvSearchState();

  void changeSiteTab(int index) {
    state = _filterBySite(state.copyWith(tabSiteIndex: index));
  }

  void appendChar(String char) {
    final newKeyword = state.keyword + char;
    state = state.copyWith(keyword: newKeyword);
    _search(newKeyword);
  }

  void deleteChar() {
    if (state.keyword.isEmpty) return;
    final newKeyword = state.keyword.substring(0, state.keyword.length - 1);
    state = state.copyWith(keyword: newKeyword);
    if (newKeyword.isEmpty) {
      state = state.copyWith(rawResults: [], searchResults: []);
    } else {
      _search(newKeyword);
    }
  }

  void clearKeyword() {
    state = const TvSearchState();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    state = state.copyWith(isLoading: true);

    try {
      final List<LiveRoom> results = [];
      final activeSites = Sites().availableSites(containsAll: false);

      for (var site in activeSites) {
        try {
          final siteRooms = await Sites.of(site.id).liveSite.searchRooms(query, page: 1, pageSize: 20);
          results.addAll(siteRooms);
        } catch (_) {}
      }

      final nextState = state.copyWith(rawResults: results, isLoading: false);
      state = _filterBySite(nextState);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  TvSearchState _filterBySite(TvSearchState currentState) {
    final currentAvailableSites = Sites().availableSites(containsAll: false);
    if (currentState.tabSiteIndex < 0 || currentState.tabSiteIndex >= currentAvailableSites.length) {
      return currentState.copyWith(searchResults: []);
    }

    final activeSite = currentAvailableSites[currentState.tabSiteIndex];
    if (activeSite.id == Sites.allSite) {
      return currentState.copyWith(searchResults: currentState.rawResults);
    }

    final filtered = currentState.rawResults
        .where((room) => room.platform.toUpperCase() == activeSite.id.toUpperCase())
        .toList();

    return currentState.copyWith(searchResults: filtered);
  }
}
