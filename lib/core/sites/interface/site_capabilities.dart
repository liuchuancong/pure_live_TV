import 'package:pure_live/core/models/index.dart';
import 'package:pure_live/core/sites/scripts/hls_source_query_policy.dart';

/// 同步自 pure_live：能力型接口集合。
/// TV 端只保留站点适配层需要的能力（无录制器/画中画消费方）。

/// Immutable public parameters sufficient to reacquire a media input.
abstract interface class LiveInputRecipe {
  String get identity;
}

/// The stream URLs returned for one requested quality together with the
/// quality that the platform actually applied.
class LivePlayUrlResolution {
  const LivePlayUrlResolution({required this.urls, this.appliedQualityData, this.qualityUnconfirmed = false})
    : sourceQueryPolicies = const {},
      inputRecipe = null;

  /// An owned input is a real source but has no exportable media URL.
  const LivePlayUrlResolution.owned({
    required LiveInputRecipe input,
    this.appliedQualityData,
    this.qualityUnconfirmed = false,
  }) : inputRecipe = input,
       urls = const [],
       sourceQueryPolicies = const {};

  LivePlayUrlResolution._({
    required this.urls,
    required this.sourceQueryPolicies,
    this.appliedQualityData,
    this.qualityUnconfirmed = false,
  }) : inputRecipe = null;

  factory LivePlayUrlResolution.withSourcePolicies({
    required List<String> urls,
    required Map<String, HlsSourceQueryPolicy> sourceQueryPolicies,
    Object? appliedQualityData,
    bool qualityUnconfirmed = false,
  }) {
    final normalized = normalizeResolvedPlayUrls(urls);
    final policies = <String, HlsSourceQueryPolicy>{};
    for (final entry in sourceQueryPolicies.entries) {
      final uri = Uri.tryParse(entry.key);
      if (!normalized.contains(entry.key) || uri == null || !entry.value.matchesSource(uri)) {
        throw const FormatException('Source query policy does not match resolved URLs');
      }
      policies[entry.key] = entry.value;
    }
    return LivePlayUrlResolution._(
      urls: normalized,
      sourceQueryPolicies: Map.unmodifiable(policies),
      appliedQualityData: appliedQualityData,
      qualityUnconfirmed: qualityUnconfirmed,
    );
  }

  LivePlayUrlResolution normalized() => inputRecipe != null
      ? this
      : LivePlayUrlResolution.withSourcePolicies(
          urls: urls,
          sourceQueryPolicies: sourceQueryPolicies,
          appliedQualityData: appliedQualityData,
          qualityUnconfirmed: qualityUnconfirmed,
        );

  final List<String> urls;
  final LiveInputRecipe? inputRecipe;
  int get lineCount => inputRecipe == null ? urls.length : 1;
  bool get hasSources => lineCount > 0;
  final Object? appliedQualityData;
  final Map<String, HlsSourceQueryPolicy> sourceQueryPolicies;
  final bool qualityUnconfirmed;
}

LivePlayQuality resolveAppliedPlayQuality({
  required List<LivePlayQuality> qualities,
  required LivePlayQuality requested,
  required LivePlayUrlResolution resolution,
}) {
  final appliedId = resolution.appliedQualityData?.toString();
  LivePlayQuality? matched;
  if (appliedId != null) {
    for (final quality in qualities) {
      if (quality.selectionId.toString() == appliedId) {
        matched = quality;
        break;
      }
    }
  }
  return (matched ?? requested).withPlaybackUnconfirmed(
    resolution.qualityUnconfirmed || (appliedId != null && matched == null),
  );
}

List<String> normalizeResolvedPlayUrls(Iterable<String> urls) {
  final result = <String>[];
  final seen = <String>{};

  for (final rawUrl in urls) {
    final url = rawUrl.trim();

    if (url.isNotEmpty && seen.add(url)) {
      result.add(url);
    }
  }

  return List<String>.unmodifiable(result);
}

abstract interface class LivePlayUrlResolver {
  Future<LivePlayUrlResolution> resolvePlayUrlsRaw({required LiveRoom detail, required LivePlayQuality quality});
}

abstract interface class LivePlayUrlCursorResolver {
  Future<LivePlayUrlResolution> resolvePlayUrlAtRaw({
    required LiveRoom detail,
    required LivePlayQuality quality,
    required int lineIndex,
  });
}

abstract interface class LivePlayRecoveryResolver {
  Future<LivePlayUrlResolution> resolvePlayUrlsForRecoveryRaw({
    required LiveRoom detail,
    required LivePlayQuality quality,
  });
}

abstract interface class LivePlayLeaseMetadata {
  DateTime? getPlayUrlRefreshAt(String url, {DateTime? now});
  DateTime? getPlayUrlInvalidAt(String url, {DateTime? now});
}

abstract interface class LiveSiteRoomRefresher {
  Future<LiveRoom> getRoomDetailForRefresh({required String roomId, required String platform});
}

abstract interface class LiveSiteRecordRoomResolver {
  Future<LiveRoom> getRoomDetailForRecording({required String roomId, required String platform});
}
