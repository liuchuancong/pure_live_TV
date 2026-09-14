// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_task_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 后台任务的配置与运行状态。
///
/// 这一层只管「记」和「读」：任务的开关、间隔、上次执行结果都落在这里，
/// 真正决定「现在该不该跑」和「跑的时候调用谁」在 `BackgroundTaskService`。
/// 拆开的好处是设置界面不需要认识任何任务实现，调度器也不需要关心界面。
///
/// 对应 iTab 扩展：配置 + 运行时间戳落在 `chrome.storage.local`，
/// 调度逻辑落在 `background.js` 的 alarm 回调里 —— 这里同样一分为二。

@ProviderFor(BackgroundTaskController)
final backgroundTaskControllerProvider = BackgroundTaskControllerProvider._();

/// 后台任务的配置与运行状态。
///
/// 这一层只管「记」和「读」：任务的开关、间隔、上次执行结果都落在这里，
/// 真正决定「现在该不该跑」和「跑的时候调用谁」在 `BackgroundTaskService`。
/// 拆开的好处是设置界面不需要认识任何任务实现，调度器也不需要关心界面。
///
/// 对应 iTab 扩展：配置 + 运行时间戳落在 `chrome.storage.local`，
/// 调度逻辑落在 `background.js` 的 alarm 回调里 —— 这里同样一分为二。
final class BackgroundTaskControllerProvider
    extends
        $NotifierProvider<BackgroundTaskController, BackgroundTaskSettings> {
  /// 后台任务的配置与运行状态。
  ///
  /// 这一层只管「记」和「读」：任务的开关、间隔、上次执行结果都落在这里，
  /// 真正决定「现在该不该跑」和「跑的时候调用谁」在 `BackgroundTaskService`。
  /// 拆开的好处是设置界面不需要认识任何任务实现，调度器也不需要关心界面。
  ///
  /// 对应 iTab 扩展：配置 + 运行时间戳落在 `chrome.storage.local`，
  /// 调度逻辑落在 `background.js` 的 alarm 回调里 —— 这里同样一分为二。
  BackgroundTaskControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundTaskControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundTaskControllerHash();

  @$internal
  @override
  BackgroundTaskController create() => BackgroundTaskController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundTaskSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundTaskSettings>(value),
    );
  }
}

String _$backgroundTaskControllerHash() =>
    r'ad3b9111208db04e75f25a3616d0e3d3c3c02080';

/// 后台任务的配置与运行状态。
///
/// 这一层只管「记」和「读」：任务的开关、间隔、上次执行结果都落在这里，
/// 真正决定「现在该不该跑」和「跑的时候调用谁」在 `BackgroundTaskService`。
/// 拆开的好处是设置界面不需要认识任何任务实现，调度器也不需要关心界面。
///
/// 对应 iTab 扩展：配置 + 运行时间戳落在 `chrome.storage.local`，
/// 调度逻辑落在 `background.js` 的 alarm 回调里 —— 这里同样一分为二。

abstract class _$BackgroundTaskController
    extends $Notifier<BackgroundTaskSettings> {
  BackgroundTaskSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<BackgroundTaskSettings, BackgroundTaskSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackgroundTaskSettings, BackgroundTaskSettings>,
              BackgroundTaskSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
