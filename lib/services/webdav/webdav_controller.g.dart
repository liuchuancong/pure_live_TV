// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webdav_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WebDavController)
final webDavControllerProvider = WebDavControllerProvider._();

final class WebDavControllerProvider
    extends $NotifierProvider<WebDavController, WebDavModel> {
  WebDavControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webDavControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webDavControllerHash();

  @$internal
  @override
  WebDavController create() => WebDavController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebDavModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebDavModel>(value),
    );
  }
}

String _$webDavControllerHash() => r'092614c18cba2b5a23e112d9ed31f1532a3e67ea';

abstract class _$WebDavController extends $Notifier<WebDavModel> {
  WebDavModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WebDavModel, WebDavModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WebDavModel, WebDavModel>,
              WebDavModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
