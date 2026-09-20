String readableCount(String info) {
  try {
    final count = int.parse(info);
    if (count > 10000) {
      // 10^4 is the unit these platforms report in, so the suffix
      // is kept verbatim instead of being localized.
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
  } catch (e) {
    return info;
  }
  return info;
}
