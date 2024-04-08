import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';

class VideoFitSetting extends StatefulWidget {
  const VideoFitSetting({
    super.key,
    required this.controller,
  });

  final SettingsService controller;

  @override
  State<VideoFitSetting> createState() => _VideoFitSettingState();
}

class _VideoFitSettingState extends State<VideoFitSetting> {
  @override
  Widget build(BuildContext context) {
    final fitmodes = {
      S.of(context).videofit_contain: BoxFit.contain,
      S.of(context).videofit_fill: BoxFit.fill,
      S.of(context).videofit_cover: BoxFit.cover,
      S.of(context).videofit_fitwidth: BoxFit.fitWidth,
      S.of(context).videofit_fitheight: BoxFit.fitHeight,
    };
    final Color color = Theme.of(context).colorScheme.primary.withOpacity(0.9);
    final isSelected = [false, false, false, false, false];
    isSelected[widget.controller.videoFitIndex.value] = true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => SwitchListTile(
              title: Text(S.of(context).settings_danmaku_open),
              contentPadding: EdgeInsets.zero,
              value: !widget.controller.hideDanmaku.value,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (bool value) => widget.controller.hideDanmaku.value = !value,
            )),
        Obx(() => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Text('弹幕合并'),
              subtitle: Text('相似度大于${widget.controller.mergeDanmuRating.value * 100}%的弹幕会被合并'),
              title: Slider(
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: widget.controller.mergeDanmuRating.value,
                onChanged: (val) => widget.controller.mergeDanmuRating.value = val,
              ),
              trailing: Text('${(widget.controller.mergeDanmuRating.value * 100).toInt()}%'),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(S.of(context).settings_videofit_title),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            selectedColor: Colors.white,
            fillColor: color,
            isSelected: isSelected,
            onPressed: (index) {
              widget.controller.videoFitIndex.value = index;
              setState(() {});
            },
            children: fitmodes.keys
                .map<Widget>((e) => Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(e, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ))
                .toList(),
          ),
        )
      ],
    );
  }
}

class DanmakuSetting extends StatelessWidget {
  const DanmakuSetting({
    super.key,
    required this.controller,
  });

  final SettingsService controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_area),
              title: Slider(
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: controller.danmakuArea.value,
                onChanged: (val) => controller.danmakuArea.value = val,
              ),
              trailing: Text(
                '${(controller.danmakuArea.value * 100).toInt()}%',
              ),
            )),
        Obx(() => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_opacity),
              title: Slider(
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: controller.danmakuOpacity.value,
                onChanged: (val) => controller.danmakuOpacity.value = val,
              ),
              trailing: Text('${(controller.danmakuOpacity.value * 100).toInt()}%'),
            )),
        Obx(() => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_speed),
              title: Slider(
                divisions: 15,
                min: 5.0,
                max: 20.0,
                value: controller.danmakuSpeed.value,
                onChanged: (val) => controller.danmakuSpeed.value = val,
              ),
              trailing: Text(controller.danmakuSpeed.value.toInt().toString()),
            )),
        Obx(() => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_fontsize),
              title: Slider(
                divisions: 20,
                min: 10.0,
                max: 30.0,
                value: controller.danmakuFontSize.value,
                onChanged: (val) => controller.danmakuFontSize.value = val,
              ),
              trailing: Text(
                controller.danmakuFontSize.value.toInt().toString(),
              ),
            )),
        Obx(() => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_fontBorder),
              title: Slider(
                divisions: 25,
                min: 0.0,
                max: 2.5,
                value: controller.danmakuFontBorder.value,
                onChanged: (val) => controller.danmakuFontBorder.value = val,
              ),
              trailing: Text(
                controller.danmakuFontBorder.value.toStringAsFixed(2),
              ),
            )),
      ],
    );
  }
}
