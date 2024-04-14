import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';

// ignore: constant_identifier_names
const TAG = 'FlutterBarrage';

class BarrageWall extends StatefulWidget {
  final BarrageWallController controller;

  /// the bullet widget
  final Widget child;

  /// time in seconds of bullet show in screen
  final int speed;

  /// used to adjust speed for each channel
  final int speedCorrectionInMilliseconds;

  final double width;
  final double height;

  /// will not send bullets to the area is safe from bottom, default is 0
  /// used to not cover the subtitles
  final int safeBottomHeight;

  /// [disable] by default, set to true will overwrite other bullets
  final bool massiveMode;

  /// used to make barrage tidy
  final double maxBulletHeight;

  /// enable debug mode, will display a debug panel with information
  final bool debug;
  final bool selfCreatedController;

  BarrageWall({
    super.key,
    List<Bullet>? bullets,
    BarrageWallController? controller,
    ValueNotifier<BarrageValue>? timelineNotifier,
    this.speed = 5,
    this.child = const SizedBox(),
    required this.width,
    required this.height,
    this.massiveMode = false,
    this.maxBulletHeight = 16,
    this.debug = false,
    this.safeBottomHeight = 0,
    this.speedCorrectionInMilliseconds = 3000,
  })  : controller = controller ?? BarrageWallController.withBarrages(bullets, timelineNotifier: timelineNotifier),
        selfCreatedController = controller == null {
    if (controller != null) {
      this.controller.value = controller.value.size == 0 ? BarrageWallValue.fromList(bullets ?? []) : controller.value;
      this.controller.timelineNotifier = controller.timelineNotifier ?? timelineNotifier;
    }
  }

  @override
  State<StatefulWidget> createState() => _BarrageState();
}

/// It's a class that holds the position of a bullet
class BulletPos {
  int id;
  int channel;
  double position; // from right to left
  double width;
  bool released = false;
  int lifetime;
  Widget widget;

  BulletPos(
      {required this.id, required this.channel, required this.position, required this.width, required this.widget})
      : lifetime = DateTime.now().millisecondsSinceEpoch;

  updateWith({required double position, double width = 0}) {
    this.position = position;
    this.width = width > 0 ? width : this.width;
    lifetime = DateTime.now().millisecondsSinceEpoch;
//    debugPrint("[$TAG] update to $this");
  }

  bool get hasExtraSpace {
    return position > width + 8;
  }

  @override
  String toString() {
    return 'BulletPos{id: $id, channel: $channel, position: $position, width: $width, released: $released, widget: $widget}';
  }
}

class _BarrageState extends State<BarrageWall> with TickerProviderStateMixin {
  late BarrageWallController _controller;
  final Random _random = Random();
  // int _processed = 0;
  // double? _width;
  // double? _height;
  double? _lastHeight; // 上一次计算通道个数的的高度记录
  late Timer _cleaner;

  double? _maxBulletHeight;
  int? _totalChannels;
  int? _channelMask;
  // Map<dynamic, BulletPos> _lastBullets = {};
  final List<int> _speedCorrectionForChannels = [];

  int _calcSafeHeight(double height) {
    if (height.isInfinite) {
      final toHeight = context.size!.height;
      debugPrint("[$TAG] height is infinite, set it to $toHeight");
      return toHeight.toInt();
    } else {
      final safeBottomHeight = _controller.safeBottomHeight ?? widget.safeBottomHeight;
      final toHeight = height - safeBottomHeight;
      debugPrint('[$TAG] safe bottom height: $safeBottomHeight, set safe height to $toHeight');
      if (toHeight < 0) {
        throw Exception('safe bottom height is too large, it should be less than $height');
      }
      return toHeight.toInt();
    }
  }

  /// null means no available channels exists
  int? _nextChannel() {
    final randomSeed = _totalChannels! - 1;

    if (_controller.usedChannel ^ _channelMask! == 0) {
      return null;
    }

    var times = 1;
    var channel = randomSeed == 0 ? 0 : _random.nextInt(randomSeed);
    var channelCode = 1 << channel;

    while (_controller.usedChannel & channelCode != 0 && _controller.usedChannel ^ _channelMask! != 0) {
      times++;
      channel = channel >= _totalChannels! ? 0 : channel + 1;
      channelCode = 1 << channel;

      /// return random channel if no channels available and massive mode is enabled
      if (times > _totalChannels!) {
        if (widget.massiveMode == true) {
          return _random.nextInt(randomSeed);
        }
        return null;
      }
    }
    // _controller.usedChannel |= (1 << channel);
    _controller.updateChannel((usedChannel) => usedChannel |= (1 << channel));
    return channel;
  }

  _releaseChannels() {
//    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < _controller.lastBullets.length; i++) {
      final channel = _controller.lastBullets.keys.elementAt(i);
      var isNotReleased = !_controller.lastBullets[channel]!.released;
      var liveTooLong =
          false; // now - _controller.lastBullets[channel].lifetime > widget.speed * 2 * 1000 + widget.speedCorrectionInMilliseconds;
      if (liveTooLong || (isNotReleased && _controller.lastBullets[channel]!.hasExtraSpace)) {
        _controller.lastBullets[channel]!.released = true;
        // _controller.usedChannel &= _channelMask! ^ 1 << channel;
        _controller.updateChannel((usedChannel) => usedChannel &= _channelMask! ^ 1 << channel);
      }
    }
  }

  void _handleBullets(
    BuildContext context, {
    required List<Bullet> bullets,
    required double width,
    double? end,
  }) {
    // cannot get the width of widget when not rendered, make a twice longer width for now
    end ??= width * 2;

    _releaseChannels();
    if (widget.debug) {
      debugPrint('[$TAG] handle bullets: ${bullets.length} - ${_controller.usedChannel.toRadixString(2)}');
    }
    for (var bullet in bullets) {
      AnimationController animationController;

      final nextChannel = _nextChannel();
      if (nextChannel != null) {}

      /// discard bullets do not have available channel and massive mode is not enabled too
      if (nextChannel == null) {
        continue;
      }

      final showTimeInMilliseconds = widget.speed * 2 * 1000 - _speedCorrectionForChannels[nextChannel];
      animationController = AnimationController(duration: Duration(milliseconds: showTimeInMilliseconds), vsync: this);
      Animation<double> animation = Tween<double>(begin: 0, end: end).animate(animationController..forward());

      final channelHeightPos = nextChannel * _maxBulletHeight!;

      /// make bullets not showed up in same time
      final fixedWidth = width + _random.nextInt(20).toDouble();
      final bulletWidget = AnimatedBuilder(
        animation: animation,
        child: bullet.child,
        builder: (BuildContext context, Widget? child) {
          if (animation.isCompleted) {
            _controller.lastBullets[nextChannel]?.updateWith(position: double.infinity);
            return const SizedBox();
          }

          double widgetWidth = 0.0;

          /// get current widget width
          if (child != null) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox?.hasSize ?? false) {
              widgetWidth = renderBox!.size.width;

              /// 通过计算出的 widget width 在判断弹幕完全移出了可视区域
              if (widgetWidth > 0 && animation.value > (fixedWidth + widgetWidth)) {
                _controller.lastBullets[nextChannel]?.updateWith(position: double.infinity);
                return const SizedBox();
              }
            }
          }

//          debugPrint(
//              '[$TAG] ${_controller.lastBullets[nextChannel]?.id} == ${context.hashCode} $child pos: ${animation.value}');
          // 【通道不为空】或者【通道的最后元素】之后出现了可以新增的元素
          if (!_controller.lastBullets.containsKey(nextChannel) ||
              (_controller.lastBullets.containsKey(nextChannel) &&
                  _controller.lastBullets[nextChannel]!.position > animation.value)) {
            _controller.lastBullets[nextChannel] = BulletPos(
                id: context.hashCode,
                channel: nextChannel,
                position: animation.value,
                width: widgetWidth,
                widget: child!);
//            debugPrint("[$TAG] add ${_controller.lastBullets[nextChannel]} - ${context.hashCode}");
          } else if (_controller.lastBullets[nextChannel]!.id == context.hashCode) {
            // 当前元素是最后元素，更新相关信息
            _controller.lastBullets[nextChannel]?.updateWith(position: animation.value, width: widgetWidth);
          } // 其他情况直接更新页面元素

          final widthPos = fixedWidth - animation.value;
          return Transform.translate(
            offset: Offset(widthPos, channelHeightPos.toDouble()),
            child: child,
          );
        },
      );
      _controller.widgets.putIfAbsent(animationController, () => bulletWidget);
    }
  }

  @override
  void didUpdateWidget(BarrageWall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller;
    }
  }

  void handleBullets() {
    if (_controller.isEnabled && _controller.value.waitingList.isNotEmpty) {
      final recallNeeded = _lastHeight != widget.height || _channelMask == null;

      if (_totalChannels == null || recallNeeded) {
        _lastHeight = widget.height;
        _maxBulletHeight = widget.maxBulletHeight;
        _totalChannels = _calcSafeHeight(widget.height) ~/ _maxBulletHeight!;
        debugPrint("[$TAG] total channels: ${_totalChannels! + 1}");
        _channelMask = (2 << _totalChannels!) - 1;

        for (var i = 0; i <= _totalChannels!; i++) {
          final nextSpeed =
              widget.speedCorrectionInMilliseconds > 0 ? _random.nextInt(widget.speedCorrectionInMilliseconds) : 0;
          _speedCorrectionForChannels.add(nextSpeed);
        }
      }

      _handleBullets(
        context,
        bullets: _controller.value.waitingList,
        width: widget.width,
      );
      // _processed += _controller.value.waitingList.length;
      setState(() {});
    }
  }

  @override
  void initState() {
    _controller = widget.controller;
    _controller.initialize();

    _controller.addListener(handleBullets);
    _controller.enabledNotifier.addListener(() {
      if (_controller.enabledNotifier.value) {
        setState(() {});
      }
    });

    _cleaner = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _controller.widgets.removeWhere((controller, widget) {
        if (controller.isCompleted) {
          controller.dispose();
          return true;
        }
        return false;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    debugPrint('[$TAG] dispose');
    _cleaner.cancel();
    _controller.clear();
    _controller.removeListener(handleBullets);
    if (widget.selfCreatedController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      if (widget.debug)
        Container(
            color: Colors.lightBlueAccent.withOpacity(0.7),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text('BarrageWallValue: ${_controller.value}'),
                  Text('TimelineNotifier: ${_controller.timelineNotifier?.value}'),
                  Text('Timeline: ${_controller.timeline}'),
                  Text('Bullets: ${_controller.widgets.length}'),
                  Text('UsedChannels: ${_controller.usedChannel.toRadixString(2)}'),
                  Text('LastBullets[0]: ${_controller.lastBullets[0]}'),
                ])),
      widget.child,
      if (_controller.isEnabled)
        Stack(fit: StackFit.loose, children: <Widget>[..._controller.widgets.values]
            // ..addAll(_widgets.values ?? const SizedBox()),
            ),
    ]);
  }
}

typedef KeyCalculator<T> = int Function(T t);

class HashList<T> {
  /// key is the showTime in minutes
  final Map<int, TreeSet<T>> _map = HashMap();
  final Comparator<T>? comparator;
  final KeyCalculator<T> keyCalculator;

  HashList({required this.keyCalculator, this.comparator});

  void appendByMinutes(List<T> values) {
    for (var value in values) {
      int key = keyCalculator(value);
      if (_map.containsKey(key)) {
        _map[key]!.add(value);
      } else {
        _map.putIfAbsent(key, () => TreeSet<T>(comparator: comparator ?? (dynamic a, b) => a.compareTo(b))..add(value));
      }
    }
  }

  @override
  String toString() {
    return 'HashList{$_map}';
  }
}

class BarrageValue {
  final int timeline;
  final bool isPlaying;

  BarrageValue({this.timeline = -1, this.isPlaying = false});

  BarrageValue copyWith({int? timeline, bool? isPlaying}) =>
      BarrageValue(timeline: timeline ?? this.timeline, isPlaying: isPlaying ?? this.isPlaying);

  @override
  String toString() {
    return 'BarrageValue{timeline: $timeline, isPlaying: $isPlaying}';
  }
}

class BarrageWallValue {
  final int showedTimeBefore;
  final int size;
  final int processedSize;
  final List<Bullet> waitingList;

  final HashList<Bullet> bullets;

  BarrageWallValue.fromList(List<Bullet> bullets, {this.showedTimeBefore = 0, this.waitingList = const []})
      : bullets = HashList<Bullet>(keyCalculator: (t) => Duration(milliseconds: t.showTime).inMinutes)
          ..appendByMinutes(bullets),
        size = bullets.length,
        processedSize = 0;

  BarrageWallValue({
    required this.bullets,
    this.showedTimeBefore = 0,
    this.waitingList = const [],
    this.size = 0,
    this.processedSize = 0,
  });

  BarrageWallValue copyWith({
    // int lastProcessedTime,
    required int processedSize,
    int? showedTimeBefore,
    List<Bullet>? waitingList,
  }) =>
      BarrageWallValue(
        bullets: bullets,
        showedTimeBefore: showedTimeBefore ?? this.showedTimeBefore,
        waitingList: waitingList ?? this.waitingList,
        size: size,
        processedSize: this.processedSize + processedSize,
      );

  @override
  String toString() {
    return 'BarrageWallValue{showedTimeBefore: $showedTimeBefore, size: $size, processed: $processedSize, waitings: ${waitingList.length}}';
  }
}

class BarrageWallController extends ValueNotifier<BarrageWallValue> {
  final Map<AnimationController, Widget> _widgets = {};
  final Map<dynamic, BulletPos> _lastBullets = {};
  int _usedChannel = 0;

  int timeline = 0;
  ValueNotifier<bool> enabledNotifier = ValueNotifier(true);
  bool _isDisposed = false;

  ValueNotifier<BarrageValue>? timelineNotifier;
  int? safeBottomHeight;
  Timer? _timer;

  bool get isEnabled => enabledNotifier.value;
  Map<AnimationController, Widget> get widgets => _widgets;
  Map<dynamic, BulletPos> get lastBullets => _lastBullets;
  int get usedChannel => _usedChannel;

  BarrageWallController({List<Bullet>? bullets, this.timelineNotifier})
      : super(BarrageWallValue.fromList(bullets ?? const []));

  BarrageWallController.withBarrages(List<Bullet>? bullets, {this.timelineNotifier})
      : super(BarrageWallValue.fromList(bullets ?? const []));

  Future<void> initialize() async {
    final Completer<void> initializingCompleter = Completer<void>();

    if (timelineNotifier == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer timer) async {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (value.size == value.processedSize) {
          /*
          timer.cancel();*/
          return;
        }

        timeline += 100;
        tryFire();
      });
    } else {
      timelineNotifier!.addListener(_handleTimelineNotifier);
    }

    initializingCompleter.complete();
    return initializingCompleter.future;
  }

  /// reset the controller to new time state
  void reset(int showedTimeBefore) {
    value = value.copyWith(showedTimeBefore: showedTimeBefore, waitingList: [], processedSize: 0);
  }

  void updateChannel(Function(int usedChannel) onUpdate) {
    _usedChannel = onUpdate(_usedChannel);
  }

  /// clear all firing bullets
  void clear() {
    /// reset all widgets animation and clear the list
    widgets.forEach((controller, widget) => controller.dispose());
    widgets.clear();
    // release channels
    _usedChannel = 0;
  }

  void _handleTimelineNotifier() {
    final offset = (timeline - timelineNotifier!.value.timeline);
    final ifNeedReset = offset.abs() > 1000;
    if (ifNeedReset) {
      debugPrint("[$TAG] offset: $offset call reset to $timeline...");
      reset(timelineNotifier!.value.timeline);
    }
    if (timelineNotifier != null) timeline = timelineNotifier!.value.timeline;
    tryFire();
  }

  tryFire({List<Bullet> bullets = const []}) {
    final key = Duration(milliseconds: timeline).inMinutes;
    final exists = value.bullets._map.containsKey(key);

    if (exists || bullets.isNotEmpty) {
      List<Bullet> toBePrecessed = value.bullets._map[key]
              ?.where((barrage) => barrage.showTime > value.showedTimeBefore && barrage.showTime <= timeline)
              .toList() ??
          [];

      if (toBePrecessed.isNotEmpty || bullets.isNotEmpty) {
        value = value.copyWith(
            showedTimeBefore: timeline,
            waitingList: toBePrecessed..addAll(bullets),
            processedSize: toBePrecessed.length);
      }
    }
  }

  disable() {
    debugPrint("[$TAG] disable barrage ... current: $enabledNotifier");
    enabledNotifier.value = false;
  }

  enable() {
    debugPrint("[$TAG] enable barrage ... current: $enabledNotifier");
    enabledNotifier.value = true;
  }

  send(List<Bullet> bullets) {
    tryFire(bullets: bullets);
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _timer?.cancel();
    }
    _isDisposed = true;
    timelineNotifier?.dispose();
    disable();
    if (!_isDisposed) {
      enabledNotifier.dispose();
    }
    super.dispose();
  }
}

class Bullet implements Comparable<Bullet> {
  final Widget child;

  /// in milliseconds
  final int showTime;

  const Bullet({required this.child, this.showTime = 0});

  @override
  String toString() {
    return 'Bullet{child: $child, showTime: $showTime}';
  }

  @override
  int compareTo(Bullet other) {
    return showTime.compareTo(other.showTime);
  }
}
