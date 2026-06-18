import 'package:pure_live/common/index.dart';

class TvPage extends StatelessWidget {
  final Widget child;

  const TvPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24), child: child),
    );
  }
}
