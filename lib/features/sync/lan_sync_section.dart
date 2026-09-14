import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/sync/lan_sync_controller.dart';
import 'package:pure_live/features/sync/sync_groups.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 「局域网同步」设置分区：TV ↔ 手机/桌面 互相发现并同步设置。
class LanSyncSectionPage extends ConsumerWidget {
  const LanSyncSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lanSyncControllerProvider);
    final controller = ref.read(lanSyncControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final runningLabel = i18nOr('ui_lan_running_on', '已开启服务');
    final subtitle = state.running ? '$runningLabel · ${state.localIp}:39888' : i18nOr('ui_lan_off_desc', '开启后，同一 Wi-Fi 下的设备可以互相发现并同步设置');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18nOr('ui_lan_sync', '局域网同步'),
                subtitle: subtitle,
                icon: Icons.lan_outlined,
                value: state.running,
                onChanged: (_) => controller.toggle(),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          _SectionLabel(text: i18nOr('ui_lan_scope', '同步内容')),
          TvSettingsCard(
            children: [
              for (final group in SyncGroups.displayOrder)
                TvSettingsSwitchTile(
                  title: _groupLabel(group),
                  subtitle: _groupHint(group),
                  icon: _groupIcon(group),
                  value: state.groups.contains(group),
                  onChanged: (_) => controller.toggleGroup(group),
                ),
            ],
          ),
          SizedBox(height: 12.sp),
          _SectionLabel(text: i18nOr('ui_lan_devices', '发现的设备')),
          TvSettingsCard(
            children: [
              if (state.devices.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
                  child: Text(
                    state.running
                        ? i18nOr('ui_lan_searching', '正在搜索同一局域网内的设备…')
                        : i18nOr('ui_lan_not_running', '同步服务未开启'),
                    style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                )
              else
                for (final device in state.devices) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.sp, 12.sp, 16.sp, 4.sp),
                    child: Row(
                      children: [
                        Icon(Icons.devices_other_rounded, size: 20.sp, color: tvTheme.focusColor),
                        SizedBox(width: 10.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                              ),
                              Text(
                                '${device.address} · ${device.platform}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
                    child: Row(
                      children: [
                        Expanded(
                          child: TvButton(
                            title: i18nOr('ui_lan_push', '推送设置'),
                            icon: Icon(Icons.upload_rounded, size: 22.sp),
                            size: TvButtonSize.medium,
                            onTap: state.busy ? null : () => controller.syncTo(device),
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: TvButton(
                            title: i18nOr('ui_lan_pull', '接收设置'),
                            icon: Icon(Icons.download_rounded, size: 22.sp),
                            size: TvButtonSize.medium,
                            isSecondary: true,
                            onTap: state.busy ? null : () => controller.pullFrom(device),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
          if (state.status.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.sp, 12.sp, 16.sp, 0),
              child: Text(state.status, style: AppTextStyles.t16W500.copyWith(color: tvTheme.focusColor)),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.sp, 12.sp, 16.sp, 0),
            child: Text(
              i18nOr('ui_lan_scope_hint', '说明：关注列表与弹幕屏蔽词属于同一份数据，会一起同步；Cookie 属于账号凭据，默认不勾选。'),
              style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  static String _groupLabel(SyncGroup group) {
    switch (group) {
      case SyncGroup.account:
        return i18nOr('ui_lan_group_account', '关注列表 + 弹幕屏蔽词');
      case SyncGroup.theme:
        return i18nOr('ui_lan_group_theme', '主题与配色');
      case SyncGroup.background:
        return i18nOr('ui_lan_group_background', '背景 / 壁纸');
      case SyncGroup.danmaku:
        return i18nOr('ui_lan_group_danmaku', '弹幕外观');
      case SyncGroup.player:
        return i18nOr('ui_lan_group_player', '播放器 / 界面 / 其它设置');
      case SyncGroup.history:
        return i18nOr('ui_lan_group_history', '观看历史');
      case SyncGroup.sensitive:
        return i18nOr('ui_lan_group_sensitive', 'Cookie / WebDAV 凭据（敏感）');
    }
  }

  static String _groupHint(SyncGroup group) {
    switch (group) {
      case SyncGroup.account:
        return i18nOr('ui_lan_group_account_hint', '收藏的房间与弹幕屏蔽词');
      case SyncGroup.theme:
        return i18nOr('ui_lan_group_theme_hint', '主题模式、加载动画样式、TV 配色板');
      case SyncGroup.background:
        return i18nOr('ui_lan_group_background_hint', '背景源、填充、遮罩与当前壁纸');
      case SyncGroup.danmaku:
        return i18nOr('ui_lan_group_danmaku_hint', '字号 / 速度 / 区域 / 透明度 / 描边');
      case SyncGroup.player:
        return i18nOr('ui_lan_group_player_hint', '播放内核、画面、页面、刷新等');
      case SyncGroup.history:
        return i18nOr('ui_lan_group_history_hint', '观看记录');
      case SyncGroup.sensitive:
        return i18nOr('ui_lan_group_sensitive_hint', '明文传输，仅在可信网络里开启');
    }
  }

  static IconData _groupIcon(SyncGroup group) {
    switch (group) {
      case SyncGroup.account:
        return Icons.favorite_border_rounded;
      case SyncGroup.theme:
        return Icons.palette_outlined;
      case SyncGroup.background:
        return Icons.wallpaper_rounded;
      case SyncGroup.danmaku:
        return Icons.subtitles_rounded;
      case SyncGroup.player:
        return Icons.play_circle_outline_rounded;
      case SyncGroup.history:
        return Icons.history_rounded;
      case SyncGroup.sensitive:
        return Icons.key_outlined;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 16.sp, 6.sp),
      child: Text(
        text,
        style: AppTextStyles.t14W600.copyWith(color: context.tvTheme.secondaryTextColor),
      ),
    );
  }
}
