import 'platform_provider.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/core/models/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_provider.g.dart';

@riverpod
class CategoryTab extends _$CategoryTab {
  @override
  int build() {
    ref.watch(platformTabProvider);
    return 0;
  }

  void switchCategory(int index) => state = index;
}

@riverpod
Future<List<LiveCategory>> getSiteCategories(Ref ref, String siteId) async {
  ref.keepAlive();
  final site = Sites.of(siteId).liveSite;
  return site.getCategores(1, 1000);
}
