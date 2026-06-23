// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BackgroundController)
final backgroundControllerProvider = BackgroundControllerProvider._();

final class BackgroundControllerProvider
    extends $NotifierProvider<BackgroundController, BackgroundConfigModel> {
  BackgroundControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundControllerHash();

  @$internal
  @override
  BackgroundController create() => BackgroundController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundConfigModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundConfigModel>(value),
    );
  }
}

String _$backgroundControllerHash() =>
    r'cbb4621dfbdbd8314335a6518316dae8450f1e57';

abstract class _$BackgroundController extends $Notifier<BackgroundConfigModel> {
  BackgroundConfigModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BackgroundConfigModel, BackgroundConfigModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackgroundConfigModel, BackgroundConfigModel>,
              BackgroundConfigModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
