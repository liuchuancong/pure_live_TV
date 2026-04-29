class LineFallbackManager {
  int _currentIndex = 0;

  String next(List<String> lines) {
    if (lines.isEmpty) {
      throw Exception('No playable line');
    }

    _currentIndex++;

    if (_currentIndex >= lines.length) {
      _currentIndex = 0;
    }

    return lines[_currentIndex];
  }

  void reset() {
    _currentIndex = 0;
  }
}
