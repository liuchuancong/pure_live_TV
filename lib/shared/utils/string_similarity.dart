/// Local implementation of the core string_similarity algorithm, the
/// Sørensen-Dice coefficient.
/// Avoids an external dependency when pub is unreachable. Equivalent to the
/// package call `StringSimilarity.compareTwoStrings`.
double compareTwoStrings(String first, String second) {
  final a = first.toLowerCase().replaceAll(RegExp(r'[^\p{L}0-9]', unicode: true), '');
  final b = second.toLowerCase().replaceAll(RegExp(r'[^\p{L}0-9]', unicode: true), '');
  if (identical(a, b)) return 1.0;
  if (a.length < 2 || b.length < 2) return (a == b) ? 1.0 : 0.0;

  final bigramsA = <String, int>{};
  for (var i = 0; i < a.length - 1; i++) {
    final g = a.substring(i, i + 2);
    bigramsA[g] = (bigramsA[g] ?? 0) + 1;
  }
  var intersection = 0;
  for (var i = 0; i < b.length - 1; i++) {
    final g = b.substring(i, i + 2);
    final count = bigramsA[g];
    if (count != null && count > 0) {
      bigramsA[g] = count - 1;
      intersection++;
    }
  }
  return (2.0 * intersection) / (a.length + b.length - 2);
}

class StringSimilarity {
  static double compareTwoStrings(String first, String second) => compareTwoStrings(first, second);
}
