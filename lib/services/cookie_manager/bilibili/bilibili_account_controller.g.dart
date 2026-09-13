// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bilibili_account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步自 pure_live：B 站账号状态控制器（业务逻辑在 BilibiliAccountService）。

@ProviderFor(BilibiliAccountController)
final bilibiliAccountControllerProvider = BilibiliAccountControllerProvider._();

/// 同步自 pure_live：B 站账号状态控制器（业务逻辑在 BilibiliAccountService）。
final class BilibiliAccountControllerProvider
    extends $NotifierProvider<BilibiliAccountController, BilibiliAccountModel> {
  /// 同步自 pure_live：B 站账号状态控制器（业务逻辑在 BilibiliAccountService）。
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
    r'31686e75018a903bbc34636bffd4ae746df4be89';

/// 同步自 pure_live：B 站账号状态控制器（业务逻辑在 BilibiliAccountService）。

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
