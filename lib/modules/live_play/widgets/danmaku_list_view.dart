import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

class DanmakuListView extends StatefulWidget {
  final LiveRoom room;

  const DanmakuListView({super.key, required this.room});

  @override
  State<DanmakuListView> createState() => DanmakuListViewState();
}

class DanmakuListViewState extends State<DanmakuListView> with AutomaticKeepAliveClientMixin<DanmakuListView> {
  final ScrollController _scrollController = ScrollController();
  bool _scrollHappen = false;

  LivePlayController get controller => Get.find<LivePlayController>();

  @override
  void initState() {
    super.initState();
    controller.messages.listen((p0) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollHappen) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linearToEaseOut,
      );
      setState(() {});
    }
  }

  bool _userScrollAction(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      setState(() => _scrollHappen = true);
    } else if (notification.direction == ScrollDirection.reverse) {
      final pos = _scrollController.position;
      if (pos.maxScrollExtent - pos.pixels <= 100) {
        setState(() => _scrollHappen = false);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: _userScrollAction,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: controller.messages.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final danmaku = controller.messages[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "${danmaku.userName}: ",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        TextSpan(
                          text: danmaku.message,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_scrollHappen)
          Positioned(
            left: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_downward_rounded),
              label: const Text('回到底部'),
              onPressed: () {
                setState(() => _scrollHappen = false);
                _scrollToBottom();
              },
            ),
          )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
