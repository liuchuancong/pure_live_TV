import 'package:flutter/material.dart';

/// App-level navigation entry point.
///
/// Services such as the IPTV/EPG importers need to show a dialog where no
/// `BuildContext` is available, so they share this single navigator key.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Current navigation context, or null before mount and after dispose.
BuildContext? get appNavigatorContext {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) return null;
  return context;
}
