import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tv_search_provider.g.dart';

class TvSearchState {
  final int tabSiteIndex;
  final int searchTypeIndex;
  final String keyword;

  const TvSearchState({this.tabSiteIndex = 0, this.searchTypeIndex = 0, this.keyword = ''});

  TvSearchState copyWith({int? tabSiteIndex, int? searchTypeIndex, String? keyword}) {
    return TvSearchState(
      tabSiteIndex: tabSiteIndex ?? this.tabSiteIndex,
      searchTypeIndex: searchTypeIndex ?? this.searchTypeIndex,
      keyword: keyword ?? this.keyword,
    );
  }
}

@Riverpod(name: 'tvSearchNotifierProvider')
class TvSearchNotifier extends _$TvSearchNotifier {
  @override
  TvSearchState build() => const TvSearchState();

  void changeSiteTab(int index) {
    state = state.copyWith(tabSiteIndex: index);
  }

  void changeSearchType(int index) {
    state = state.copyWith(searchTypeIndex: index);
  }

  void updateKeyword(String text) {
    state = state.copyWith(keyword: text);
  }

  void reset() {
    state = const TvSearchState();
  }
}
