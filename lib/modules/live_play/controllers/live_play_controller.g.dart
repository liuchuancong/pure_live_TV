// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_play_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 直播播放页控制器（移植自 pure_live LivePlayController / PlayerController，
/// 按 TV 场景收敛：无 PiP/多画面/竖屏/录制/IPTV EPG/音频直连）。
///
/// 职责：
/// - 进入房间：拉取房间详情、清晰度列表、播放地址，驱动 PlayerManager 起播
/// - 跟随 PlayerManager 流更新 UI 状态（buffering/playing/paused/error）
/// - 清晰度/线路切换、重试、播放暂停、音量与画面比例
/// - 弹幕会话由 [DanmakuSessionController] 单独承载

@ProviderFor(LivePlayController)
final livePlayControllerProvider = LivePlayControllerFamily._();

/// 直播播放页控制器（移植自 pure_live LivePlayController / PlayerController，
/// 按 TV 场景收敛：无 PiP/多画面/竖屏/录制/IPTV EPG/音频直连）。
///
/// 职责：
/// - 进入房间：拉取房间详情、清晰度列表、播放地址，驱动 PlayerManager 起播
/// - 跟随 PlayerManager 流更新 UI 状态（buffering/playing/paused/error）
/// - 清晰度/线路切换、重试、播放暂停、音量与画面比例
/// - 弹幕会话由 [DanmakuSessionController] 单独承载
final class LivePlayControllerProvider
    extends $NotifierProvider<LivePlayController, LivePlayState> {
  /// 直播播放页控制器（移植自 pure_live LivePlayController / PlayerController，
  /// 按 TV 场景收敛：无 PiP/多画面/竖屏/录制/IPTV EPG/音频直连）。
  ///
  /// 职责：
  /// - 进入房间：拉取房间详情、清晰度列表、播放地址，驱动 PlayerManager 起播
  /// - 跟随 PlayerManager 流更新 UI 状态（buffering/playing/paused/error）
  /// - 清晰度/线路切换、重试、播放暂停、音量与画面比例
  /// - 弹幕会话由 [DanmakuSessionController] 单独承载
  LivePlayControllerProvider._({
    required LivePlayControllerFamily super.from,
    required LivePlayArgs super.argument,
  }) : super(
         retry: null,
         name: r'livePlayControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$livePlayControllerHash();

  @override
  String toString() {
    return r'livePlayControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LivePlayController create() => LivePlayController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LivePlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LivePlayState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LivePlayControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$livePlayControllerHash() =>
    r'a5535e82bd3bddb29e3a1f7a76ee8c0a01064f27';

/// 直播播放页控制器（移植自 pure_live LivePlayController / PlayerController，
/// 按 TV 场景收敛：无 PiP/多画面/竖屏/录制/IPTV EPG/音频直连）。
///
/// 职责：
/// - 进入房间：拉取房间详情、清晰度列表、播放地址，驱动 PlayerManager 起播
/// - 跟随 PlayerManager 流更新 UI 状态（buffering/playing/paused/error）
/// - 清晰度/线路切换、重试、播放暂停、音量与画面比例
/// - 弹幕会话由 [DanmakuSessionController] 单独承载

final class LivePlayControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LivePlayController,
          LivePlayState,
          LivePlayState,
          LivePlayState,
          LivePlayArgs
        > {
  LivePlayControllerFamily._()
    : super(
        retry: null,
        name: r'livePlayControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 直播播放页控制器（移植自 pure_live LivePlayController / PlayerController，
  /// 按 TV 场景收敛：无 PiP/多画面/竖屏/录制/IPTV EPG/音频直连）。
  ///
  /// 职责：
  /// - 进入房间：拉取房间详情、清晰度列表、播放地址，驱动 PlayerManager 起播
  /// - 跟随 PlayerManager 流更新 UI 状态（buffering/playing/paused/error）
  /// - 清晰度/线路切换、重试、播放暂停、音量与画面比例
  /// - 弹幕会话由 [DanmakuSessionController] 单独承载

  LivePlayControllerProvider call(LivePlayArgs args) =>
      LivePlayControllerProvider._(argument: args, from: this);

  @override
  String toString() => r'livePlayControllerProvider';
}

/// 直播播放页控制器（移植自 pure_live LivePlayController / PlayerController，
/// 按 TV 场景收敛：无 PiP/多画面/竖屏/录制/IPTV EPG/音频直连）。
///
/// 职责：
/// - 进入房间：拉取房间详情、清晰度列表、播放地址，驱动 PlayerManager 起播
/// - 跟随 PlayerManager 流更新 UI 状态（buffering/playing/paused/error）
/// - 清晰度/线路切换、重试、播放暂停、音量与画面比例
/// - 弹幕会话由 [DanmakuSessionController] 单独承载

abstract class _$LivePlayController extends $Notifier<LivePlayState> {
  late final _$args = ref.$arg as LivePlayArgs;
  LivePlayArgs get args => _$args;

  LivePlayState build(LivePlayArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LivePlayState, LivePlayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LivePlayState, LivePlayState>,
              LivePlayState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 房间弹幕会话：每个 [LivePlayArgs] 一条，负责弹幕传输连接、
/// 消息门控/去重过滤，以及向 flame_barrage 渲染层和列表视图分发消息。
///
/// 移植自 pure_live 的 DanmakuController（TV 收敛版：无 PiP 会话、
/// 无本地消息互动、无关键字屏蔽 UI；过滤器字段沿用全局设置模型）。

@ProviderFor(DanmakuSessionController)
final danmakuSessionControllerProvider = DanmakuSessionControllerFamily._();

/// 房间弹幕会话：每个 [LivePlayArgs] 一条，负责弹幕传输连接、
/// 消息门控/去重过滤，以及向 flame_barrage 渲染层和列表视图分发消息。
///
/// 移植自 pure_live 的 DanmakuController（TV 收敛版：无 PiP 会话、
/// 无本地消息互动、无关键字屏蔽 UI；过滤器字段沿用全局设置模型）。
final class DanmakuSessionControllerProvider
    extends $NotifierProvider<DanmakuSessionController, DanmakuSessionState> {
  /// 房间弹幕会话：每个 [LivePlayArgs] 一条，负责弹幕传输连接、
  /// 消息门控/去重过滤，以及向 flame_barrage 渲染层和列表视图分发消息。
  ///
  /// 移植自 pure_live 的 DanmakuController（TV 收敛版：无 PiP 会话、
  /// 无本地消息互动、无关键字屏蔽 UI；过滤器字段沿用全局设置模型）。
  DanmakuSessionControllerProvider._({
    required DanmakuSessionControllerFamily super.from,
    required LivePlayArgs super.argument,
  }) : super(
         retry: null,
         name: r'danmakuSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$danmakuSessionControllerHash();

  @override
  String toString() {
    return r'danmakuSessionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DanmakuSessionController create() => DanmakuSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DanmakuSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DanmakuSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DanmakuSessionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$danmakuSessionControllerHash() =>
    r'd504ff183c861a50fde5068df00e7e09496293ad';

/// 房间弹幕会话：每个 [LivePlayArgs] 一条，负责弹幕传输连接、
/// 消息门控/去重过滤，以及向 flame_barrage 渲染层和列表视图分发消息。
///
/// 移植自 pure_live 的 DanmakuController（TV 收敛版：无 PiP 会话、
/// 无本地消息互动、无关键字屏蔽 UI；过滤器字段沿用全局设置模型）。

final class DanmakuSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DanmakuSessionController,
          DanmakuSessionState,
          DanmakuSessionState,
          DanmakuSessionState,
          LivePlayArgs
        > {
  DanmakuSessionControllerFamily._()
    : super(
        retry: null,
        name: r'danmakuSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 房间弹幕会话：每个 [LivePlayArgs] 一条，负责弹幕传输连接、
  /// 消息门控/去重过滤，以及向 flame_barrage 渲染层和列表视图分发消息。
  ///
  /// 移植自 pure_live 的 DanmakuController（TV 收敛版：无 PiP 会话、
  /// 无本地消息互动、无关键字屏蔽 UI；过滤器字段沿用全局设置模型）。

  DanmakuSessionControllerProvider call(LivePlayArgs args) =>
      DanmakuSessionControllerProvider._(argument: args, from: this);

  @override
  String toString() => r'danmakuSessionControllerProvider';
}

/// 房间弹幕会话：每个 [LivePlayArgs] 一条，负责弹幕传输连接、
/// 消息门控/去重过滤，以及向 flame_barrage 渲染层和列表视图分发消息。
///
/// 移植自 pure_live 的 DanmakuController（TV 收敛版：无 PiP 会话、
/// 无本地消息互动、无关键字屏蔽 UI；过滤器字段沿用全局设置模型）。

abstract class _$DanmakuSessionController
    extends $Notifier<DanmakuSessionState> {
  late final _$args = ref.$arg as LivePlayArgs;
  LivePlayArgs get args => _$args;

  DanmakuSessionState build(LivePlayArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DanmakuSessionState, DanmakuSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DanmakuSessionState, DanmakuSessionState>,
              DanmakuSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
