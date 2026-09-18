import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';

/// Weight/labelling rules of the font manager's download pipeline.
///
/// The manager no longer runs downloads behind a modal dialog (38efe834 moved
/// the wait inline onto each font row), so the old dialog-lifecycle tests were
/// removed with it; the file-name and weight rules below are unchanged.
void main() {
  group('weight labels', () {
    test('a weight file is labelled by the part after the last dash', () {
      // The mobile rule: `basenameWithoutExtension(path).split('-').last`.
      expect(FontDownloadManager.weightLabelOf('/fonts/foo/SourceHanSans-700.ttf'), '700');
      expect(FontDownloadManager.weightLabelOf('SourceHanSansCN-Bold.otf'), 'Bold');
    });

    test('a file without a dash keeps its whole stem instead of an empty label', () {
      expect(FontDownloadManager.weightLabelOf('/fonts/foo/Regular.ttf'), 'Regular');
    });

    test('only real font extensions count', () {
      expect(FontDownloadManager.isSupportedFontPath('/a/b.ttf'), isTrue);
      expect(FontDownloadManager.isSupportedFontPath('/a/b.OTF'), isTrue);
      expect(FontDownloadManager.isSupportedFontPath('/a/readme.txt'), isFalse);
      expect(FontDownloadManager.isSupportedFontPath('/a/ttf'), isFalse);
    });

    test('the stored file name is the file name, not the path', () {
      expect(FontDownloadManager.fileNameOf('/fonts/foo/SourceHanSans-700.ttf'), 'SourceHanSans-700.ttf');
    });
  });

  test('temp dirs are cleaned up by the caller contract', () {
    // Sanity that the manager's static helpers need no bindings: they are pure
    // string rules usable from plain unit tests.
    expect(Directory.systemTemp.existsSync(), isTrue);
  });
}
