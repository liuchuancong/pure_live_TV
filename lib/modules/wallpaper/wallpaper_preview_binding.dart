import 'package:get/get.dart';
import 'package:pure_live/modules/wallpaper/wallpaper_preview_controller.dart';

class WallpaperPreviewBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => WallpaperPreviewController())];
  }
}
