import 'dart:collection';
import 'package:pure_live/shared/models/live_room/live_room.dart';

/// Last known metadata of the rooms the app has shown, in memory only.
///
/// Entering a room is two steps: the page draws a card from what the list
/// carried, while the site's authoritative detail request runs behind it. An
/// entry that carries nothing but platform and room id — a link, a restored
/// list snapshot, a room switched to from history — has no card to draw, so it
/// seeds from here instead and the screen is never a black page with no text.
///
/// Nothing is persisted: a fresh process simply starts with an empty cache and
/// every room falls back to the plain id-only hint, exactly as before.
class LiveRoomHintCache {
  LiveRoomHintCache._();

  /// Rooms kept at once. This is a display seed, not a store: the entry room
  /// and the rooms around it are all the player ever asks for.
  static const int _capacity = 12;

  /// Insertion order doubles as recency, so the oldest entry is dropped first.
  static final LinkedHashMap<String, LiveRoom> _rooms = LinkedHashMap<String, LiveRoom>();

  static String _keyOf(String platform, String roomId) => '${platform.trim().toLowerCase()}:${roomId.trim()}';

  /// Last metadata seen for a room, or null when nothing is known about it.
  static LiveRoom? lookup(String platform, String roomId) {
    final key = _keyOf(platform, roomId);
    final room = _rooms.remove(key);

    // Re-insert so a room the viewer keeps coming back to is not evicted by
    // rooms that were only passed through.
    if (room != null) _rooms[key] = room;

    return room;
  }

  /// Remembers [room].
  ///
  /// A room with no metadata is ignored on purpose: an id-only hint would
  /// otherwise overwrite the card a list already provided, which is the exact
  /// loss this cache exists to prevent.
  static void remember(LiveRoom? room) {
    if (room == null || !room.hasMetadata) return;

    final key = room.identityKey;

    if (key == ':') return;

    _rooms.remove(key);
    _rooms[key] = room;

    while (_rooms.length > _capacity) {
      _rooms.remove(_rooms.keys.first);
    }
  }
}
