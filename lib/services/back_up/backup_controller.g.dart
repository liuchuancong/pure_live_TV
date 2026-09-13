// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步自 pure_live BackupController：全量设置导出/校验/导入/恢复。

@ProviderFor(BackupController)
final backupControllerProvider = BackupControllerProvider._();

/// 同步自 pure_live BackupController：全量设置导出/校验/导入/恢复。
final class BackupControllerProvider
    extends $NotifierProvider<BackupController, void> {
  /// 同步自 pure_live BackupController：全量设置导出/校验/导入/恢复。
  BackupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupControllerHash();

  @$internal
  @override
  BackupController create() => BackupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupControllerHash() => r'5a416a315366729c16ada0df9a141b0c1b762d83';

/// 同步自 pure_live BackupController：全量设置导出/校验/导入/恢复。

abstract class _$BackupController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
