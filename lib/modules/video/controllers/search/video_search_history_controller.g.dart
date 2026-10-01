// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_search_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Video-mode search keywords, the reference app's search history: persisted
/// through [HivePrefUtil], capped at [maxLength], a repeat moves back to the
/// top. Separate from the live mode's history on purpose.

@ProviderFor(VideoSearchHistoryController)
final videoSearchHistoryControllerProvider =
    VideoSearchHistoryControllerProvider._();

/// Video-mode search keywords, the reference app's search history: persisted
/// through [HivePrefUtil], capped at [maxLength], a repeat moves back to the
/// top. Separate from the live mode's history on purpose.
final class VideoSearchHistoryControllerProvider
    extends $NotifierProvider<VideoSearchHistoryController, List<String>> {
  /// Video-mode search keywords, the reference app's search history: persisted
  /// through [HivePrefUtil], capped at [maxLength], a repeat moves back to the
  /// top. Separate from the live mode's history on purpose.
  VideoSearchHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoSearchHistoryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoSearchHistoryControllerHash();

  @$internal
  @override
  VideoSearchHistoryController create() => VideoSearchHistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$videoSearchHistoryControllerHash() =>
    r'f160af71e88cc107a717a0e0206f1fc3300aa78f';

/// Video-mode search keywords, the reference app's search history: persisted
/// through [HivePrefUtil], capped at [maxLength], a repeat moves back to the
/// top. Separate from the live mode's history on purpose.

abstract class _$VideoSearchHistoryController extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
