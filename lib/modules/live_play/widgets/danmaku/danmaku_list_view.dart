import 'package:pure_live/theme/index.dart';
import 'package:pure_live/core/exports/package_export.dart';
import 'package:pure_live/modules/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/modules/live_play/models/live_play_args.dart';
import 'package:pure_live/core/models/live_message/live_message_model.dart';

/// 右侧面板的弹幕消息列表（移植自 pure_live danmaku_list_view.dart 的 TV 收敛版）。
///
/// 差异：TV 无长按互动/屏蔽/举报菜单，仅展示滚动历史；
/// 消息去重与相似度过滤已在上游 [DanmakuSessionController] 完成。
class DanmakuListView extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const DanmakuListView({super.key, required this.args});

  @override
  ConsumerState<DanmakuListView> createState() => _DanmakuListViewState();
}

class _DanmakuListViewState extends ConsumerState<DanmakuListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(danmakuSessionControllerProvider(widget.args));
    final tvTheme = context.tvTheme;
    final messages = session.messages;

    if (messages.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        child: Text(
          session.statusText ?? '暂无弹幕',
          style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
        ),
      );
    }

    _scrollToBottom();
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _MessageTile(message: messages[index]);
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  final LiveMessage message;

  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final isChat = message.type == LiveMessageType.chat;
    final color = Color.fromARGB(255, message.color.r, message.color.g, message.color.b);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Text.rich(
        TextSpan(
          children: [
            if (isChat)
              TextSpan(
                text: '${message.userName}：',
                style: AppTextStyles.t14W600.copyWith(color: tvTheme.secondaryTextColor),
              ),
            TextSpan(
              text: message.message,
              style: AppTextStyles.t14W500.copyWith(color: isChat ? color : tvTheme.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
