import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal structural repro for the AccountCookiePage layout: does the
/// LayoutBuilder + IntrinsicHeight + Flexible combination alone throw the
/// relayout-boundary / wrong-build-scope assertions?
void main() {
  testWidgets('intrinsic row with flexible children rebuilds cleanly', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var rebuilds = 0;

    Widget page() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool bounded = constraints.maxHeight.isFinite;
          final double fillHeight = bounded ? constraints.maxHeight : 0;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: fillHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: fillHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('title ${rebuilds++}')),
                          Text('badge'),
                        ],
                      ),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(
                              flex: 4,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('left title'),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 200,
                                          child: Center(child: Text('qr $rebuilds')),
                                        ),
                                        SizedBox(height: 12),
                                        Text('status'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('right title'),
                                  Text('manual $rebuilds'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page())));
    await tester.pump();

    // Rebuild the page a few times, as the QR poll timer would.
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: page())));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
