// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_management_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagManagementController)
final tagManagementControllerProvider = TagManagementControllerProvider._();

final class TagManagementControllerProvider
    extends $NotifierProvider<TagManagementController, TagManagementModel> {
  TagManagementControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagManagementControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagManagementControllerHash();

  @$internal
  @override
  TagManagementController create() => TagManagementController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagManagementModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagManagementModel>(value),
    );
  }
}

String _$tagManagementControllerHash() =>
    r'1f95105c2fbda3b9d689b11d734c3acbb941b951';

abstract class _$TagManagementController extends $Notifier<TagManagementModel> {
  TagManagementModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TagManagementModel, TagManagementModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TagManagementModel, TagManagementModel>,
              TagManagementModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
