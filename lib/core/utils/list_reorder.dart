/// [items] with [id] placed at [targetIndex]; the entries it passes shift by one
/// and nothing is dropped.
///
/// Shared by the ordering pages (side-menu entries, visible platforms): "who you
/// pick is who moves, and you say where it goes". [targetIndex] is clamped to the
/// list, an unknown [id] or an empty list leaves [items] untouched, and the input
/// list is never mutated.
List<String> reorderIds(List<String> items, String id, int targetIndex) {
  final index = items.indexOf(id);
  if (index < 0 || items.isEmpty) return List<String>.from(items);
  final target = targetIndex.clamp(0, items.length - 1);
  if (target == index) return List<String>.from(items);
  final next = List<String>.from(items)..removeAt(index);
  next.insert(target, id);
  return next;
}
