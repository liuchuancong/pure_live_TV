extension TextUtilsStringExtension on String {
  bool toBoolean() {
    return toLowerCase() == "true" ? true : false;
  }
}
