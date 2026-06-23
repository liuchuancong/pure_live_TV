String readableCount(String info) {
  try {
    int count = int.parse(info);
    if (count > 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
  } catch (e) {
    return info;
  }
  return info;
}
