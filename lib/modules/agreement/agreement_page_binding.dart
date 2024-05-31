import 'package:get/get.dart';
import 'package:pure_live/modules/agreement/agreement_page_controller.dart';

class AgreementPageBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => AgreementPageController())];
  }
}
