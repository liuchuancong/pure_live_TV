import 'dart:convert';

/// A collision-free database identity; feed IDs remain separately available for
/// exact TVG-ID matching. JSON framing also handles delimiters inside either ID.
String epgChannelKey(String sourceId, String channelId) => 'epg:${jsonEncode([sourceId, channelId])}';
