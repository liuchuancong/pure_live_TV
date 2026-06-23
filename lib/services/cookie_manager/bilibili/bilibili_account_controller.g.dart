// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bilibili_account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BilibiliAccountController)
final bilibiliAccountControllerProvider = BilibiliAccountControllerProvider._();

final class BilibiliAccountControllerProvider
    extends $NotifierProvider<BilibiliAccountController, BilibiliAccountModel> {
  BilibiliAccountControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bilibiliAccountControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bilibiliAccountControllerHash();

  @$internal
  @override
  BilibiliAccountController create() => BilibiliAccountController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BilibiliAccountModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BilibiliAccountModel>(value),
    );
  }
}

String _$bilibiliAccountControllerHash() =>
    r'47e394682458a2fa15eda9baf98e687e43a8f2b0';

abstract class _$BilibiliAccountController
    extends $Notifier<BilibiliAccountModel> {
  BilibiliAccountModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BilibiliAccountModel, BilibiliAccountModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BilibiliAccountModel, BilibiliAccountModel>,
              BilibiliAccountModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
