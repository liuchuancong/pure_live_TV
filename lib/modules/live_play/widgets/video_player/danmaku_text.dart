import 'package:pure_live/common/index.dart';
import 'package:bordered_text/bordered_text.dart';

class DanmakuText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final Color color;
  final double fontSize;
  final double strokeWidth;

  const DanmakuText(
    this.text, {
    this.textAlign = TextAlign.left,
    this.color = Colors.white,
    this.fontSize = 16,
    this.strokeWidth = 2.0,
    super.key,
  });

  Color get borderColor {
    var brightness = ((color.r * 299) + (color.g * 587) + (color.b * 114)) / 1000;
    return brightness > 70 ? Colors.black54 : Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return BorderedText(
      strokeWidth: strokeWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
      strokeColor: borderColor,
      child: Text(
        text,
        softWrap: false,
        textAlign: textAlign,
        style: TextStyle(
          decoration: TextDecoration.none,
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }
}
