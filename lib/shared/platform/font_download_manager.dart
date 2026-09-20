import 'dart:developer';
import 'dart:io' hide HttpClient;
import 'package:dio/dio.dart' show CancelToken;
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:pure_live/shared/platform/race_http.dart';
import 'package:pure_live/shared/models/index.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/utils/githup_mirror.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';

/// Thrown out of [FontDownloadManager.downloadFontFamily] when the download was
/// cancelled through [FontDownloadManager.cancelDownload], so the caller can
/// tell "cancelled" from "failed" (a failure wipes the family's folder; a
/// cancellation keeps the weights that finished).
class FontDownloadCancelled implements Exception {
  const FontDownloadCancelled();
}

/// Downloads and registers the cloud font families.
///
/// The behaviour mirrors the mobile app's `FontDownloadManager`, because the two share
/// the same download folder layout and the same manifest: a family is a folder of
/// weight files (`700.ttf`, `400.ttf`, …), one file can be registered on its own, and
/// nothing is registered until the caller asks for it.
class FontDownloadManager {
  FontDownloadManager._();
  static final FontDownloadManager instance = FontDownloadManager._();

  /// The extensions a family may be made of, as in the mobile app's file policy.
  static const List<String> supportedExtensions = <String>['.ttf', '.otf'];

  static bool isSupportedFontPath(String path) {
    final String lower = path.toLowerCase();
    return supportedExtensions.any(lower.endsWith);
  }

  /// The in-flight download per family; its presence *is* "downloading".
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};

  bool isDownloading(String fontId) => _cancelTokens.containsKey(fontId);

  /// Cancels the running download of [fontId], mid-file included (the token
  /// reaches the HTTP layer). Finished weight files stay on disk; only the
  /// partial `.part` file is dropped, so a later download resumes.
  void cancelDownload(String fontId) => _cancelTokens[fontId]?.cancel('cancelled by user');

  /// The file name of one weight, e.g. `SourceHanSans-700.ttf`.
  static String fileNameOf(String filePath) => p.basename(filePath);

  /// The label the weight picker shows for one file.
  ///
  /// `SourceHanSans-700.ttf` → `700`: the mobile app's rule
  /// (`basenameWithoutExtension(path).split('-').last`). A file without a `-` keeps
  /// its whole stem, so the row never ends up empty.
  static String weightLabelOf(String filePath) {
    final String stem = p.basenameWithoutExtension(filePath);
    final String label = stem.split('-').last;
    return label.isEmpty ? stem : label;
  }

  Future<String> get _fontRootPath async => (await AppPathManager().fontRootDir).path;

  Future<Directory> fontFamilyDir(String fontId) async => Directory(p.join(await _fontRootPath, fontId));

  /// Every usable weight file of one family, sorted by path so the picker's order is
  /// stable across restarts.
  ///
  /// A file that exists but is empty is a half-finished download, not a font.
  Future<List<File>> listDownloadedFontFiles(String fontId) async {
    final Directory fontDir = await fontFamilyDir(fontId);
    if (!await fontDir.exists()) return const <File>[];

    final List<File> files = <File>[];
    await for (final entity in fontDir.list()) {
      if (entity is! File || !isSupportedFontPath(entity.path)) continue;
      if (await entity.length() > 0) files.add(entity);
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  Future<bool> checkFontDownloaded(String fontId) async => (await listDownloadedFontFiles(fontId)).isNotEmpty;

  /// Registers the family with the engine, optionally only [fileName].
  ///
  /// Returns whether anything was registered. The caller needs that answer: the family
  /// may have been deleted behind the setting's back, or the weight it was locked to may
  /// be missing, and both mean "fall back" rather than "applied" — the mobile app's
  /// `activateFontFamily` verifies the same way before it persists anything.
  Future<bool> loadFont(String fontId, {String fileName = ''}) async {
    try {
      final List<File> files = await listDownloadedFontFiles(fontId);
      if (files.isEmpty) return false;

      final loader = FontLoader(fontId);
      bool registered = false;

      for (final File file in files) {
        if (fileName.isNotEmpty && p.basename(file.path) != fileName) continue;
        loader.addFont(file.readAsBytes().then(ByteData.sublistView));
        registered = true;
        // A locked weight means exactly that one file.
        if (fileName.isNotEmpty) break;
      }

      if (!registered) return false;
      await loader.load();
      log('FontLoader registered family: $fontId${fileName.isEmpty ? '' : ' ($fileName)'}');
      return true;
    } catch (e) {
      log('Font registration sequence failed: $e');
      return false;
    }
  }

  /// Downloads every weight file of [fontModel] and reports progress through
  /// [onStateChanged].
  ///
  /// It deliberately does **not** register the family: which file (or all of them)
  /// becomes active is the caller's decision, and that is also what keeps a halted
  /// download from half-applying a family.
  Future<bool> downloadFontFamily({
    required FontModel fontModel,
    required Function(DownloadState) onStateChanged,
  }) async {
    final root = await _fontRootPath;
    final fontId = fontModel.id;
    final fontDir = Directory(p.join(root, fontId));

    if (!await fontDir.exists()) {
      await fontDir.create(recursive: true);
    }

    final cancelToken = CancelToken();
    _cancelTokens[fontId] = cancelToken;

    onStateChanged(DownloadState.downloading);
    log('Starting block download pipeline for font family: $fontId');

    try {
      final mirror = GitHubMirror(owner: 'liuchuancong', repo: 'fonts', branch: 'master');

      for (final filePath in fontModel.files) {
        if (cancelToken.isCancelled) throw const FontDownloadCancelled();
        final fileName = p.basename(filePath);
        final file = File(p.join(fontDir.path, fileName));

        if (await file.exists()) {
          final length = await file.length();
          if (length == 0) {
            await file.delete();
          } else {
            continue;
          }
        }

        final urls = mirror.mirrors(filePath);
        final fastestUrl = await RaceHttp.findFastestUrl(urls);
        int retryCount = 0;
        const maxRetries = 3;

        while (retryCount < maxRetries) {
          if (cancelToken.isCancelled) throw const FontDownloadCancelled();
          try {
            await HttpClient.instance.download(
              fastestUrl!,
              file.path,
              cancel: cancelToken,
              header: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            );

            if (await file.exists() && await file.length() > 0) {
              break;
            }
            throw Exception('File is empty or corrupted');
          } catch (e) {
            if (cancelToken.isCancelled) throw const FontDownloadCancelled();
            retryCount++;
            if (file.existsSync()) {
              try {
                file.deleteSync();
              } catch (_) {}
            }
            if (retryCount >= maxRetries) {
              throw Exception('Failed to sync file slice: $fileName');
            }
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      onStateChanged(DownloadState.downloaded);
      return true;
    } on FontDownloadCancelled {
      // A cancelled download keeps the weights that already finished (so a retry
      // skips them); only the partial `.part` temp file goes.
      if (await fontDir.exists()) {
        await for (final entity in fontDir.list()) {
          if (entity is File && entity.path.endsWith('.part')) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
      onStateChanged(DownloadState.notDownloaded);
      // The caller distinguishes "cancelled" from "failed" by this exception.
      throw const FontDownloadCancelled();
    } catch (e, s) {
      log('Font bundle sync sequence aborted: $e, retry count exceeded $s');
      onStateChanged(DownloadState.notDownloaded);

      if (await fontDir.exists()) {
        try {
          await fontDir.delete(recursive: true);
        } catch (_) {}
      }
      return false;
    } finally {
      _cancelTokens.remove(fontId);
    }
  }

  Future<void> deleteFontFamily(FontModel fontModel, Function(DownloadState) onStateChanged) async {
    try {
      final fontDir = await fontFamilyDir(fontModel.id);
      if (await fontDir.exists()) {
        await fontDir.delete(recursive: true);
      }
      onStateChanged(DownloadState.notDownloaded);
    } catch (e) {
      log('Failed to delete font family: $e');
    }
  }
}
