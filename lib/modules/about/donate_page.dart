import 'package:pure_live/common/index.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return Scaffold(appBar: AppBar(title: Text(S.of(context).support_donate)), body: const WechatItem());
    });
  }
}

class WechatItem extends StatelessWidget {
  const WechatItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/images/wechat.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
