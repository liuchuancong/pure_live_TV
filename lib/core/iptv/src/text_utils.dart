import 'package:pure_live/core/iptv/src/text_utils_string_extension.dart';

Map<String, String> getKeyValueList(String input, List<String> separator) {
  var result = <String, String>{};

  if (input.isNullEmptyOrWhitespace) {
    return result;
  }

  input = input.trim();
  if (input.startsWith(',')) {
    input = input.substring(1);
  }

  var escape = false;
  var quoted = false;
  var startIndex = 0;
  var delimIndex = 0;

  final regExp = RegExp(
    '(^[\\s"]*)|([\\s"]+\$)',
  );

  void addKeyValue(int endIndex) {
    if (delimIndex > startIndex) {
      var key = input
          .substring(startIndex, delimIndex)
          .replaceAll('\\"', '"')
          .replaceAll(regExp, '');
      var value = input
          .substring(delimIndex + 1, endIndex)
          .replaceAll('\\"', '"')
          .replaceAll(regExp, '');

      result[key] = value;
    }
  }

  for (var i = 0; i < input.length; i++) {
    var c = input[i];

    if (c == '\\' && !escape) {
      escape = true;
    } else {
      if (c == '"' && !escape) {
        quoted = !quoted;
      } else if (!quoted) {
        if (separator.contains(c)) {
          addKeyValue(i);

          delimIndex = 0;
          startIndex = i + 1;
        } else if (c == '=') {
          delimIndex = i;
        }
      }

      escape = false;
    }
  }

  addKeyValue(input.length);

  return result;
}
