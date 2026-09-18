import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class TvDigitalClock extends StatelessWidget {
  final TextStyle? style;
  final String format;
  const TvDigitalClock({super.key, this.style, this.format = 'HH:mm'});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final timeData = snapshot.data!;
        final String formattedDateTime = DateFormat(format).format(timeData);

        return Text(formattedDateTime, style: style);
      },
    );
  }
}
