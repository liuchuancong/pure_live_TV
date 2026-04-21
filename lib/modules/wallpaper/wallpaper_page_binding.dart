import 'package:get/get.dart';
import 'package:pure_live/modules/wallpaper/wallpaper_page_controller.dart';

class WallpaperPageBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => WallpaperPageController())];
  }
}
