// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_download_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global font-download pipeline.
///
/// The state lives here, not in the manager page, so a download keeps running
/// (and applies itself when it finishes) after the user leaves the page —
/// `keepAlive` keeps the provider alive for the whole session. Clicking a
/// family starts its download; clicking it again while it downloads cancels.

@ProviderFor(FontDownloadController)
final fontDownloadControllerProvider = FontDownloadControllerProvider._();

/// Global font-download pipeline.
///
/// The state lives here, not in the manager page, so a download keeps running
/// (and applies itself when it finishes) after the user leaves the page —
/// `keepAlive` keeps the provider alive for the whole session. Clicking a
/// family starts its download; clicking it again while it downloads cancels.
final class FontDownloadControllerProvider
    extends
        $NotifierProvider<
          FontDownloadController,
          Map<String, FontDownloadPhase>
        > {
  /// Global font-download pipeline.
  ///
  /// The state lives here, not in the manager page, so a download keeps running
  /// (and applies itself when it finishes) after the user leaves the page —
  /// `keepAlive` keeps the provider alive for the whole session. Clicking a
  /// family starts its download; clicking it again while it downloads cancels.
  FontDownloadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontDownloadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontDownloadControllerHash();

  @$internal
  @override
  FontDownloadController create() => FontDownloadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, FontDownloadPhase> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, FontDownloadPhase>>(
        value,
      ),
    );
  }
}

String _$fontDownloadControllerHash() =>
    r'0315daf2ca1236fbce06f1f9662d4070863d82e8';

/// Global font-download pipeline.
///
/// The state lives here, not in the manager page, so a download keeps running
/// (and applies itself when it finishes) after the user leaves the page —
/// `keepAlive` keeps the provider alive for the whole session. Clicking a
/// family starts its download; clicking it again while it downloads cancels.

abstract class _$FontDownloadController
    extends $Notifier<Map<String, FontDownloadPhase>> {
  Map<String, FontDownloadPhase> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, FontDownloadPhase>,
              Map<String, FontDownloadPhase>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, FontDownloadPhase>,
                Map<String, FontDownloadPhase>
              >,
              Map<String, FontDownloadPhase>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
