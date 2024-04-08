import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pure_live/common/index.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  final widgets = const [WechatItem()];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      final width = constraint.maxWidth;
      final crossAxisCount = width > 640 ? 2 : 1;
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).support_donate)),
        body: MasonryGridView.count(
          physics: const BouncingScrollPhysics(),
          crossAxisCount: crossAxisCount,
          itemCount: 1,
          itemBuilder: (BuildContext context, int index) => widgets[index],
        ),
      );
    });
  }
}

class WechatItem extends StatelessWidget {
  const WechatItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionTitle(title: 'Wechat'),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/images/wechat.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
