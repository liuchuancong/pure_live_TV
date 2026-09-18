import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';

/// Danmaku block list: keywords and blocked users. Both lists live in the
/// favorites controller so playback and settings read the same state.
class DanmakuShieldSectionPage extends ConsumerStatefulWidget {
  const DanmakuShieldSectionPage({super.key});

  @override
  ConsumerState<DanmakuShieldSectionPage> createState() => DanmakuShieldSectionPageState();
}

class DanmakuShieldSectionPageState extends ConsumerState<DanmakuShieldSectionPage> {
  final _keyword = TextEditingController();
  final _user = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _keyword.dispose();
    _user.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final controller = ref.read(favoriteRoomControllerProvider.notifier);
    final ok = controller.addShieldList(_keyword.text);
    setState(() => _result = ok ? i18n('danmaku_keyword_blocked') : i18n('ui_parameter_error'));
    if (ok) _keyword.clear();
  }

  void _addUser() {
    final controller = ref.read(favoriteRoomControllerProvider.notifier);
    final ok = controller.addBlockedDanmakuUser(_user.text);
    setState(() => _result = ok ? i18n('danmaku_user_blocked') : i18n('ui_parameter_error'));
    if (ok) _user.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoriteRoomControllerProvider);
    final theme = context.tvTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: RemoteSyncQrCard(width: 280)),
          SizedBox(height: 20.sp),
          // keyword shield
          TvSettingsGroupTitle(title: i18n('danmaku_keyword_block')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('danmaku_keyword_block'),
                subtitle: i18n('block_danmaku_keyword'),
                icon: Icons.filter_alt_outlined,
                options: [i18n('add')],
                index: 0,
                onChanged: (_) => _addKeyword(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TvInputField(controller: _keyword, hint: i18n('block_danmaku_keyword')),
              ),
              for (var i = 0; i < state.shieldList.length; i++)
                TvSettingsOptionTile(
                  title: state.shieldList[i],
                  icon: Icons.block_rounded,
                  options: [i18n('delete')],
                  index: 0,
                  onChanged: (_) => ref.read(favoriteRoomControllerProvider.notifier).removeShieldList(i),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('blocked_danmaku_users', args: {'count': '${state.blockedDanmakuUsers.length}'}),
                subtitle: i18n('block_danmaku_user'),
                icon: Icons.person_off_outlined,
                options: [i18n('add')],
                index: 0,
                onChanged: (_) => _addUser(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TvInputField(controller: _user, hint: i18n('block_danmaku_user')),
              ),
              for (var i = 0; i < state.blockedDanmakuUsers.length; i++)
                TvSettingsOptionTile(
                  title: state.blockedDanmakuUsers[i],
                  icon: Icons.person_off_outlined,
                  options: [i18n('delete')],
                  index: 0,
                  onChanged: (_) => ref.read(favoriteRoomControllerProvider.notifier).removeBlockedDanmakuUser(i),
                ),
            ],
          ),
          if (_result.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(_result, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
            ),
        ],
      ),
    );
  }
}
