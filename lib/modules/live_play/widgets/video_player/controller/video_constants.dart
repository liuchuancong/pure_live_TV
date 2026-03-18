/// 视频控制器常量
class VideoConstants {
  /// 控制器自动隐藏延迟（5秒）
  static const controllerAutoHideDelay = Duration(seconds: 5);

  /// 名称显示时长（2秒）
  static const showNameDuration = Duration(milliseconds: 2000);

  /// 双击判定时长（500毫秒）
  static const doubleClickDuration = Duration(milliseconds: 500);

  /// 滚动动画时长（300毫秒）
  static const scrollAnimationDuration = Duration(milliseconds: 300);

  /// 键盘事件节流延迟（100毫秒）
  static const keyThrottleDelay = 100;

  /// 列表项高度（用于滚动计算）
  static const scrollItemHeight = 100.0;
}

/// 弹幕参数常量（提取扩展中的静态常量）
class DanmakuConstants {
  static final Map<double, String> sizeMap = {
    10.0: "10",
    12.0: "12",
    14.0: "14",
    16.0: "16",
    18.0: "18",
    20.0: "20",
    22.0: "22",
    24.0: "24",
    28.0: "28",
    32.0: "32",
    40.0: "40",
    48.0: "48",
    64.0: "64",
    72.0: "72",
  };

  static final Map<double, String> speedMap = {
    4.0: "速度1",
    6.0: "速度2",
    8.0: "速度3",
    10.0: "速度4",
    12.0: "速度5",
    14.0: "速度6",
    16.0: "速度7",
    18.0: "速度8",
    20.0: "速度9",
    22.0: "速度10",
    24.0: "速度11",
    26.0: "速度12",
    28.0: "速度13",
    30.0: "速度14",
    32.0: "速度15",
  };

  static final Map<double, String> areaMap = {
    0.1: '10%',
    0.2: '20%',
    0.3: '30%',
    0.4: '40%',
    0.5: '50%',
    0.6: '60%',
    0.7: '70%',
    0.8: '80%',
    0.9: '90%',
    1.0: '100%',
  };

  static final Map<double, String> distanceMap = {
    0.0: '0',
    5.0: '5',
    10.0: '10',
    15.0: '15',
    20.0: '20',
    25.0: '25',
    30.0: '30',
    35.0: '35',
    40.0: '40',
    50.0: '50',
    70.0: '70',
    100.0: '100',
  };

  static final Map<double, String> strokeMap = {
    0.0: "2",
    1.0: "4",
    2.0: "6",
    3.0: "8",
    4.0: "10",
    5.0: "12",
    6.0: "14",
    7.0: "16",
    8.0: "18",
  };
}
