// Translation helpers.
//
// Pure easy_localization: every string lives in assets/translations and
// follows the language setting. The old offline `_labels` table is gone —
// a missing key reads as the key itself, which shows up in development.
import 'package:easy_localization/easy_localization.dart' as ez;

/// The translated text of [key], with `{name}` placeholders replaced from
/// [args].
String i18n(String key, {Map<String, String>? args}) {
  var text = ez.tr(key);
  args?.forEach((name, value) {
    text = text.replaceAll('{$name}', value);
  });
  return text;
}

/// [i18n] when [key] exists in the translation assets, otherwise [fallback].
String i18nOr(String key, String fallback, {Map<String, String>? args}) {
  if (!i18nExists(key)) return fallback;
  return i18n(key, args: args);
}

bool i18nExists(String key) => ez.trExists(key);
