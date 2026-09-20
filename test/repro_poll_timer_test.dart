import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repro candidate: the AccountCookiePage layout (LayoutBuilder whose builder
/// runs during layout, IntrinsicHeight + Flexible) combined with a child that
/// setStates from a Timer, like the QR login poll does every 3 seconds.
void main() {
  testWidgets('timer-driven setState inside layout builder does not corrupt the tree', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double fillHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: fillHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('title'),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(
                                flex: 4,
                                child: _PollingChild(),
                              ),
                              const Flexible(flex: 6, child: Column(children: [Text('right')])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Ten seconds of polling, one second per frame.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(tester.takeException(), isNull);
  });
}

class _PollingChild extends StatefulWidget {
  @override
  State<_PollingChild> createState() => _PollingChildState();
}

class _PollingChildState extends State<_PollingChild> {
  int ticks = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => ticks++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('left $ticks'),
        if (ticks.isEven)
          const SizedBox(height: 200, child: Center(child: Text('qr')))
        else
          const SizedBox(height: 180, child: Center(child: Text('scanned'))),
      ],
    );
  }
}
