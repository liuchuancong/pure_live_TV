import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class IjkPlayerView extends StatefulWidget {
  final String url;
  final bool softDecoder;
  final VoidCallback? onCreated;
  final Map<String, dynamic> headers;
  const IjkPlayerView({super.key, required this.url, this.onCreated, required this.softDecoder, required this.headers});

  @override
  State<IjkPlayerView> createState() => _IjkPlayerViewState();
}

class _IjkPlayerViewState extends State<IjkPlayerView> {
  late MethodChannel _channel;
  static const String viewType = 'plugins.mystyle.purelive/ijk_player';

  @override
  void initState() {
    super.initState();
    _channel = MethodChannel('plugins.mystyle.purelive/ijk_player_control');
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType,
        creationParams: {
          'url': widget.url,
          'softDecoder': widget.softDecoder,
          'headers': widget.headers,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _channel.invokeMethod('init', id);
          widget.onCreated?.call();
        },
      );
    } else {
      return const Center(child: Text('仅支持 Android'));
    }
  }

  // 控制方法
  Future<void> play() async => _channel.invokeMethod('play');
  Future<void> pause() async => _channel.invokeMethod('pause');
  Future<void> seekTo(int ms) async => _channel.invokeMethod('seekTo', ms);
  Future<void> disposePlayer() async => _channel.invokeMethod('dispose');

  @override
  dispose() {
    disposePlayer();
    super.dispose();
  }
}
