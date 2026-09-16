import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';
import 'package:pure_live/shared/pagination/models/paging_model.dart';
import 'package:pure_live/shared/pagination/models/paging_param.dart';

/// The source tree, available synchronously.
final backgroundCatalogProvider = Provider<BackgroundCatalog>(
  (ref) => BackgroundRepository.instance.loadCatalog(),
);

/// Paging parameters, one cached instance per (source, category).
///
/// [PagingParam] holds closures, and the paging core is a family provider keyed
/// by the param **instance**: building a fresh param on every rebuild would look
/// like a different provider and refetch the whole category each time. Caching
/// by source+category keeps the identity stable, exactly like the hot page's
/// per-site cache.
final Map<String, PagingParam<BackgroundItem>> _paramCache =
    <String, PagingParam<BackgroundItem>>{};

/// Entries shown per grid slice. The core re-slices a fixed server page, so this
/// only controls how many items a scroll step adds.
const int kWallpaperClientPageSize = 24;

PagingParam<BackgroundItem> wallpaperPagingParam(
  BackgroundSource source,
  BackgroundCategory category,
) {
  final String key = '${source.id}|${category.id}';
  final cached = _paramCache[key];
  if (cached != null) return cached;

  final repository = BackgroundRepository.instance;
  final PagingParam<BackgroundItem> param;

  if (repository.isLocalSource(source.id)) {
    // Solid colours, live wallpapers and deepin are compiled in / fixed URLs:
    // hand the whole list over once and let the core slice it.
    param = PagingParam<BackgroundItem>(
      mode: PagingMode.serverAll,
      pageSize: kWallpaperClientPageSize,
      keepAlive: true,
      fetchAll: () async => repository.localItems(source.id),
    );
  } else {
    param = PagingParam<BackgroundItem>(
      mode: PagingMode.serverFixedSize,
      pageSize: kWallpaperClientPageSize,
      fixedServerSize: repository.serverPageSize(source.id),
      keepAlive: true,
      fetchFixed: (page, size) => repository.fetchPage(
        source: source,
        category: category,
        page: page,
        size: size,
      ),
    );
  }

  _paramCache[key] = param;
  return param;
}
