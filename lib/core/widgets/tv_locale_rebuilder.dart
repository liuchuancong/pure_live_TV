import 'package:flutter/material.dart';

/// Rebuilds its whole subtree, in place, whenever the app's locale changes.
///
/// `i18n()` reads easy_localization's current locale globally (`ez.tr`) instead of
/// depending on the `Localizations` widget, so a language change rebuilds nothing by
/// itself: only the widgets that happened to rebuild for some other reason picked the new
/// strings up. Language switches logged but only took effect after several attempts - every
/// label waited for an unrelated rebuild (a focus move, a page push, a settings change)
/// before it spoke the new language.
///
/// Easy localization's own locale change does not fix it either: the app is a `const`
/// child of it, so its rebuild is skipped — `updateChild` sees the identical widget and
/// returns the existing element untouched.
///
/// Marking every element below dirty re-runs each `build` with the new locale while every
/// `State` survives, which is why a plain widget works here rather than a keyed
/// `KeyedSubtree`: scroll offsets, the player and the kept-alive tabs keep working, and
/// the keyboard stays on the node it was on. The marking happens after the frame, since
/// an element may not be marked dirty while the tree is being built.
class TvLocaleRebuilder extends StatefulWidget {
  const TvLocaleRebuilder({super.key, required this.child});

  final Widget child;

  @override
  State<TvLocaleRebuilder> createState() => _TvLocaleRebuilderState();
}

class _TvLocaleRebuilderState extends State<TvLocaleRebuilder> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depending on `Localizations` makes this rebuild on a language change.
    final Locale? locale = Localizations.maybeLocaleOf(context);
    if (locale == null || locale == _locale) return;
    final bool firstRun = _locale == null;
    _locale = locale;
    // The first frame is already built with this locale — nothing to refresh.
    if (firstRun) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rebuildSubtree(context as Element);
    });
  }

  /// Marks every element below [element] dirty, children first.
  ///
  /// The walk is what matters: rebuilding only the top would hand the same `const`
  /// widgets down again, and `updateChild` skips an element whose widget did not change,
  /// so a `const` label would keep its old text. Every element rebuilding itself is
  /// the guarantee this widget exists for.
  static void _rebuildSubtree(Element element) {
    element.visitChildren(_rebuildSubtree);
    if (element is ComponentElement) {
      // A no-op for anything that is no longer active, and the next frame rebuilds the
      // rest — `build` with the same widget, so no `State` is lost.
      element.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
