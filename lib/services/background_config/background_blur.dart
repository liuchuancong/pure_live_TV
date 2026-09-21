import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// 给媒体类背景（图片 / 视频 / 播放期海报帧）套上高斯模糊。
///
/// 纯色与渐变不套：模糊一个纯色画面不会改变任何像素，白付一次离屏合成。
/// [sigma] 为 0 时直接返回原 widget，避免多一层 saveLayer。
///
/// 注意这是逐帧的 GPU 合成，sigma 越大代价越高；预设上限 48 已足够做
/// "背景虚化、前景清晰"的观感，再大在电视盒子上会掉帧。
Widget wallpaperBlurred(Widget child, double sigma) {
  if (sigma <= 0) return child;
  return ImageFiltered(
    imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
    child: child,
  );
}
