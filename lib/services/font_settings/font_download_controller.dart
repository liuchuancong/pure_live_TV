import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/font_model/font_model.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'font_settings_controller.dart';

part 'font_download_controller.g.dart';

/// The download phase of one family, as the manager rows show it.
enum FontDownloadPhase { idle, downloading, failed }

/// Global font-download pipeline.
///
/// The state lives here, not in the manager page, so a download keeps running
/// (and applies itself when it finishes) after the user leaves the page —
/// `keepAlive` keeps the provider alive for the whole session. Clicking a
/// family starts its download; clicking it again while it downloads cancels.
@Riverpod(keepAlive: true)
class FontDownloadController extends _$FontDownloadController {
  @override
  Map<String, FontDownloadPhase> build() => const <String, FontDownloadPhase>{};

  bool isDownloading(String fontId) => state[fontId] == FontDownloadPhase.downloading;

  /// Downloads [font] in the background and applies it on success.
  ///
  /// Multi-weight families apply as a whole (auto): nobody is on the page to
  /// answer the weight picker, and the user can still lock a single weight by
  /// clicking the family again once it is downloaded.
  Future<void> startDownload(FontModel font, {bool danmaku = false}) async {
    if (isDownloading(font.id)) return;
    state = <String, FontDownloadPhase>{...state, font.id: FontDownloadPhase.downloading};

    try {
      await FontDownloadManager.instance.downloadFontFamily(fontModel: font, onStateChanged: (_) {});

      // Register before activating so the family renders immediately, and
      // refresh the disk sizes the manager cards display.
      await FontDownloadManager.instance.loadFont(font.id);
      if (danmaku) {
        await ref.read(danmakuSettingsControllerProvider.notifier).activateDanmakuFontFamily(font);
      } else {
        await ref.read(fontSettingsControllerProvider.notifier).activateFontFamily(font);
      }
      await ref.read(fontSettingsControllerProvider.notifier).refreshFontDiskSizes(force: true);
      state = <String, FontDownloadPhase>{...state, font.id: FontDownloadPhase.idle};
    } on FontDownloadCancelled {
      state = <String, FontDownloadPhase>{...state, font.id: FontDownloadPhase.idle};
      ToastUtil.show(i18n('font_download_cancelled'));
    } catch (_) {
      state = <String, FontDownloadPhase>{...state, font.id: FontDownloadPhase.failed};
      ToastUtil.show(i18n('font_download_failed'));
    }
  }

  /// Cancels the running download of [fontId]; [startDownload] reports it.
  void cancel(String fontId) => FontDownloadManager.instance.cancelDownload(fontId);
}
