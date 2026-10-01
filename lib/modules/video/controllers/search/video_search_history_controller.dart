import 'package:pure_live/exports/common_export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_search_history_controller.g.dart';

/// Video-mode search keywords, the reference app's search history: persisted
/// through [HivePrefUtil], capped at [maxLength], a repeat moves back to the
/// top. Separate from the live mode's history on purpose.
@Riverpod(keepAlive: true)
class VideoSearchHistoryController extends _$VideoSearchHistoryController {
  static const String _storageKey = 'videoSearchHistory';
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
