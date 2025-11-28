import 'dart:ui' as ui;
import 'models/danmaku_item.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/pkg/canvas_danmaku/utils/utils.dart';

class ScrollDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> scrollDanmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final int fontWeight;
  final bool showStroke;
  final double danmakuHeight;
  final bool running;
  final int tick;
  final int batchThreshold;

  final double totalDuration;
  final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.green;

  ScrollDanmakuPainter(
    this.progress,
    this.scrollDanmakuItems,
    this.danmakuDurationInSeconds,
    this.fontSize,
    this.fontWeight,
    this.showStroke,
    this.danmakuHeight,
    this.running,
    this.tick, {
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  }) : totalDuration = danmakuDurationInSeconds * 1000;

  @override
  void paint(Canvas canvas, Size size) {
    final startPosition = size.width;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas pictureCanvas = Canvas(pictureRecorder);
    _drawDanmakus(pictureCanvas, size, startPosition);
    final ui.Picture picture = pictureRecorder.endRecording();
    canvas.drawPicture(picture);
  }

  void _drawDanmakus(Canvas canvas, Size size, double startPosition) {
    for (var item in scrollDanmakuItems) {
      item.lastDrawTick ??= item.creationTime;
      final currentWidth = Utils.calculateMixedContentWidth(item.content, fontSize);
      final endPosition = -currentWidth; // 使用临时宽度计算结束位置
      final distance = startPosition - endPosition;
      item.xPosition = item.xPosition + (((item.lastDrawTick! - tick) / totalDuration) * distance);
      if (item.xPosition < -currentWidth || item.xPosition > size.width) {
        continue;
      }
      Utils.drawMixedContent(
        canvas,
        item.content,
        Offset(item.xPosition, item.yPosition),
        fontSize,
        fontWeight,
        showStroke,
        item.content.selfSend,
        selfSendPaint,
      );
      item.lastDrawTick = tick;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
