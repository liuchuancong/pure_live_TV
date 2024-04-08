import 'dart:async';
import 'video_controller.dart';
import 'video_controller_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PlayerFull extends StatefulWidget {
  const PlayerFull({super.key, required this.controller, required this.routePageBuilder, required this.playerView});

  final VideoController controller;

  final PlayerFullRoutePageBuilder routePageBuilder;

  final Widget playerView;
  @override
  State<PlayerFull> createState() => _PlayerFullState();
}

class _PlayerFullState extends State<PlayerFull> with WidgetsBindingObserver {
  ///Flag which determines if widget has initialized
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    widget.controller.isFullscreen.listen(onControllerEvent);
    widget.controller.videoFit.listen((p0) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    if (!_initialized) {
      _initialized = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }

  void onControllerEvent(bool isOpen) {
    debugPrint('Widget $isOpen is $isOpen% visible');
    onFullScreenChanged();
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    // ignore: use_build_context_synchronously
    await Navigator.of(context, rootNavigator: true).push(route);
  }

  // ignore: avoid_void_async
  Future<void> onFullScreenChanged() async {
    final controller = widget.controller;
    if (controller.isFullscreen.value) {
      await _pushFullScreenWidget(context);
    } else {
      widget.controller.setPortraitOrientation();
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = PlayerFullProvider(controller: widget.controller, child: _buildPlayer());

    final routePageBuilder = widget.routePageBuilder;

    return routePageBuilder(context, animation, secondaryAnimation, controllerProvider);
  }

  Widget _buildPlayer() {
    return VisibilityDetector(
      key: Key("${widget.controller.hashCode}_key"),
      onVisibilityChanged: (VisibilityInfo visibilityInfo) {},
      child: widget.playerView,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    VisibilityDetectorController.instance.forget(Key("${widget.controller.hashCode}_key"));
    super.dispose();
  }
}

class PlayerFullProvider extends InheritedWidget {
  const PlayerFullProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  final VideoController controller;

  @override
  bool updateShouldNotify(PlayerFullProvider oldWidget) => controller != oldWidget.controller;
}

typedef PlayerFullRoutePageBuilder = Widget Function(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, PlayerFullProvider controllerProvider);

class MobileFullscreen extends StatefulWidget {
  const MobileFullscreen({
    super.key,
    required this.controller,
    required this.controllerProvider,
  });

  final VideoController controller;
  final Widget controllerProvider;

  @override
  State<MobileFullscreen> createState() => _MobileFullscreenState();
}

class _MobileFullscreenState extends State<MobileFullscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.controllerProvider,
            VideoControllerPanel(controller: widget.controller),
          ],
        ),
      ),
    );
  }
}
