import 'package:pure_live/pkg/canvas_danmaku/models/danmaku_option.dart';
import 'package:pure_live/pkg/canvas_danmaku/models/danmaku_content_item.dart';

class DanmakuController {
  Function(DanmakuContentItem)? _onAddDanmaku;
  Function(DanmakuOption)? _onUpdateOption;
  Function? _onPause;
  Function? _onResume;
  Function? _onClear;

  DanmakuController({
    required Function(DanmakuContentItem) onAddDanmaku,
    required Function(DanmakuOption) onUpdateOption,
    required Function onPause,
    required Function onResume,
    required Function onClear,
  }) : _onAddDanmaku = onAddDanmaku,
       _onUpdateOption = onUpdateOption,
       _onPause = onPause,
       _onResume = onResume,
       _onClear = onClear;

  // 添加setter方法允许更新回调
  set onAddDanmaku(Function(DanmakuContentItem) callback) => _onAddDanmaku = callback;
  set onUpdateOption(Function(DanmakuOption) callback) => _onUpdateOption = callback;
  set onPause(Function callback) => _onPause = callback;
  set onResume(Function callback) => _onResume = callback;
  set onClear(Function callback) => _onClear = callback;

  bool running = true;

  DanmakuOption option = DanmakuOption();

  void pause() => _onPause?.call();
  void resume() => _onResume?.call();
  void clear() => _onClear?.call();
  void addDanmaku(DanmakuContentItem item) => _onAddDanmaku?.call(item);
  void updateOption(DanmakuOption option) => _onUpdateOption?.call(option);
}
