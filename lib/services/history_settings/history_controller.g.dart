// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HistoryController)
final historyControllerProvider = HistoryControllerProvider._();

final class HistoryControllerProvider
    extends $NotifierProvider<HistoryController, HistoryModel> {
  HistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyControllerHash();

  @$internal
  @override
  HistoryController create() => HistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryModel>(value),
    );
  }
}

String _$historyControllerHash() => r'b05989fd7365d97bdac60827a237fd6c11e27137';

abstract class _$HistoryController extends $Notifier<HistoryModel> {
  HistoryModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HistoryModel, HistoryModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryModel, HistoryModel>,
              HistoryModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
