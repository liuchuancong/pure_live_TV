import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class TvDigitalClock extends StatelessWidget {
  final TextStyle? style;

  const TvDigitalClock({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final timeData = snapshot.data!;
        final String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timeData);

        return Text(
          formattedDateTime,
          style: style,
        );
      },
    );
  }
}
