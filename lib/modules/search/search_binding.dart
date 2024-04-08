import 'package:get/get.dart';

import 'search_controller.dart';

class SearchBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => SearchController())];
  }
}
