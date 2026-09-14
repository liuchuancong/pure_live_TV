import '../models/channel.dart';

class PlaylistParseResult {
  final List<IptvChannel> channels;
  final List<String> errors;

  const PlaylistParseResult({required this.channels, this.errors = const []});

  bool get hasErrors => errors.isNotEmpty;

  int get channelCount => channels.length;
}
