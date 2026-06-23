// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_config_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RefreshConfigController)
final refreshConfigControllerProvider = RefreshConfigControllerProvider._();

final class RefreshConfigControllerProvider
    extends $NotifierProvider<RefreshConfigController, RefreshConfigModel> {
  RefreshConfigControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refreshConfigControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refreshConfigControllerHash();

  @$internal
  @override
  RefreshConfigController create() => RefreshConfigController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefreshConfigModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefreshConfigModel>(value),
    );
  }
}

String _$refreshConfigControllerHash() =>
    r'79692a23c17206a1fba751677914cd17c0f114b3';

abstract class _$RefreshConfigController extends $Notifier<RefreshConfigModel> {
  RefreshConfigModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RefreshConfigModel, RefreshConfigModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RefreshConfigModel, RefreshConfigModel>,
              RefreshConfigModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
