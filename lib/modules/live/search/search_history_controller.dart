import 'package:pure_live/exports/common_export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_history_controller.g.dart';

/// Recent search keywords, persisted via [HivePrefUtil] and capped at
/// [maxLength]; a repeated keyword moves back to the top instead of duping.
@Riverpod(keepAlive: true)
class SearchHistoryController extends _$SearchHistoryController {
  static const String _storageKey = 'searchHistory';
  static const int maxLength = 15;

  @override
  List<String> build() => HivePrefUtil.getStringList(_storageKey) ?? [];

  void add(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    state = [trimmed, ...state.where((entry) => entry != trimmed)].take(maxLength).toList();
    _persist();
  }

  void remove(String keyword) {
    state = state.where((entry) => entry != keyword).toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  void _persist() => HivePrefUtil.setStringList(_storageKey, state);
}
