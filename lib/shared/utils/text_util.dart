String readableCount(String info) {
  try {
    final count = int.parse(info);
    if (count > 10000) {
      // 万 is the ten-thousand unit these platforms report in, so the suffix
      // is kept verbatim instead of being localized.
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
  } catch (e) {
    return info;
  }
  return info;
}
