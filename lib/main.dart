import 'package:flutter/material.dart';
import 'package:pure_live/app/app.dart';
import 'package:pure_live/global/initialized.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  final initializer = AppInitializer();
  await initializer.initialize();

  runApp(UncontrolledProviderScope(container: initializer.container, child: const App()));
}
