import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/app_status_view.dart';

/// Business contexts an "empty" state can appear in, so every page shows an
/// icon, copy and action that mean something for *its* data instead of the
/// generic 暂无数据 + 重新加载 pair (a 关注 page with nothing followed has
/// nothing to reload — it needs a nudge towards search instead).
enum EmptyScene { favorite, hot, history, favoriteAreas, searchResult, areaRooms, generic }

/// What the action button of an empty state does.
enum EmptySceneAction {
  /// Reload the current list (server-driven data may simply be empty right now).
  retry,

  /// Jump somewhere useful; the [EmptyScene] knows where.
  goSearch,
  goHot,

  /// Purely informational; no button at all.
  none,
}

class _EmptySceneStyle {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final EmptySceneAction action;

  const _EmptySceneStyle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    required this.action,
  });
}

_EmptySceneStyle _styleFor(EmptyScene scene) {
  switch (scene) {
    case EmptyScene.favorite:
      return _EmptySceneStyle(
        icon: Icons.favorite_border_rounded,
        title: i18nOr('empty_favorite_title', 'No followed rooms yet'),
        subtitle: i18nOr('empty_favorite_subtitle', 'Search for a streamer you like, or browse the hot list'),
        actionLabel: i18nOr('empty_favorite_action', 'Go to search'),
        action: EmptySceneAction.goSearch,
      );
    case EmptyScene.hot:
      return _EmptySceneStyle(
        icon: Icons.local_fire_department_outlined,
        title: i18nOr('empty_hot_title', 'No live rooms on this platform right now'),
        subtitle: i18nOr('empty_hot_subtitle', 'Try another platform, or check back later'),
        action: EmptySceneAction.retry,
      );
    case EmptyScene.history:
      return _EmptySceneStyle(
        icon: Icons.history_rounded,
        title: i18nOr('empty_history_title', 'No watch history yet'),
        subtitle: i18nOr('empty_history_subtitle', 'Rooms you watch are remembered here automatically'),
        actionLabel: i18nOr('empty_history_action', 'Browse hot'),
        action: EmptySceneAction.goHot,
      );
    case EmptyScene.favoriteAreas:
      return _EmptySceneStyle(
        icon: Icons.folder_special_outlined,
        title: i18nOr('empty_favorite_areas_title', 'No favorite folders yet'),
        subtitle: i18nOr('empty_favorite_areas_subtitle', 'Add categories to a folder to collect whole groups of rooms'),
        action: EmptySceneAction.retry,
      );
    case EmptyScene.searchResult:
      return _EmptySceneStyle(
        icon: Icons.search_off_rounded,
        title: i18nOr('empty_search_title', 'No matching live rooms'),
        subtitle: i18nOr('empty_search_subtitle', 'Try another keyword, or switch platform / search type'),
        action: EmptySceneAction.retry,
      );
    case EmptyScene.areaRooms:
      return _EmptySceneStyle(
        icon: Icons.category_outlined,
        title: i18nOr('empty_area_rooms_title', 'No live rooms in this category'),
        subtitle: i18nOr('empty_area_rooms_subtitle', 'Try another category, or check back later'),
        action: EmptySceneAction.retry,
      );
    case EmptyScene.generic:
      return _EmptySceneStyle(
        icon: Icons.live_tv_rounded,
        title: i18n('status_empty_title'),
        subtitle: i18n('status_empty_subtitle'),
        action: EmptySceneAction.retry,
      );
  }
}

/// Builds the [AppStatusView] for a business [scene].
///
/// [onGoSearch]/[onGoHot] switch the home side menu; when a scene wants that
/// navigation but the caller cannot provide it, the button falls back to
/// [onRetry] with a plain 重新加载 label.
AppStatusView sceneEmptyView(
  BuildContext context, {
  required EmptyScene scene,
  required VoidCallback onRetry,
  VoidCallback? onGoSearch,
  VoidCallback? onGoHot,
}) {
  final style = _styleFor(scene);
  final VoidCallback? action = switch (style.action) {
    EmptySceneAction.retry => onRetry,
    EmptySceneAction.goSearch => onGoSearch ?? onRetry,
    EmptySceneAction.goHot => onGoHot ?? onRetry,
    EmptySceneAction.none => null,
  };
  final String actionLabel = switch (style.action) {
    EmptySceneAction.goSearch when onGoSearch != null => style.actionLabel!,
    EmptySceneAction.goHot when onGoHot != null => style.actionLabel!,
    EmptySceneAction.none => '',
    _ => i18nOr('retry', 'Retry'),
  };

  return AppStatusView(
    type: AppStatusType.empty,
    icon: style.icon,
    title: style.title,
    subtitle: style.subtitle,
    buttonText: actionLabel.isEmpty ? null : actionLabel,
    onTap: action,
  );
}
