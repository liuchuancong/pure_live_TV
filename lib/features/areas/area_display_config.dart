import 'package:pure_live/shared/models/live_area/live_area.dart';
import 'package:pure_live/shared/models/live_category/live_category.dart';

/// 各站点的分区目录展示配置。
///
/// 站点 [`LiveSite.getCategores`] 统一返回两层结构（一级分类 + children）。
/// 分区页默认按一级分类做二级 tab；但对分类很少的站点（bigo、zhanqi、
/// showroom 这类只有一层，或一级下总共没几项的），一层 tab 反而把内容
/// 切碎了 —— 把 children 全部平铺到一个列表里一次展示完更直观。
///
/// 在 [flatAreaSites] 里登记的平台走平铺展示；未登记的保持两层 tab。
/// （单层站点无需登记 —— [shouldFlattenCategories] 会对它们自动平铺。）
const Set<String> flatAreaSites = <String>{
  'bigo',
  'zhanqi',
  'showroom',
};

/// 该站点的分区目录是否应平铺展示。
///
/// 两种情形：
/// * 站点只返回一个一级分类 —— 平铺等于把 children 直接铺开，一层空 tab
///   没有信息量，自动生效；
/// * 站点在 [flatAreaSites] 里登记 —— 分类虽有多组，但总量少，一次展示
///   全部比切 tab 更直观。
bool shouldFlattenCategories(String siteId, List<LiveCategory> categories) =>
    categories.length <= 1 || isFlatAreaSite(siteId);

/// 将站点的两层分类目录平铺为一个列表。
///
/// 每个二级分类保留其所属一级分类的名字（[LiveArea.typeName] 已由站点层
/// 填好），平铺只做展开不重排。
List<LiveArea> flattenCategories(List<LiveCategory> categories) {
  return <LiveArea>[
    for (final category in categories) ...category.children,
  ];
}

/// 该站点是否按平铺模式展示分区目录。
bool isFlatAreaSite(String siteId) => flatAreaSites.contains(siteId.trim().toLowerCase());
