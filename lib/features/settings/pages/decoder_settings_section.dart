import 'dart:io';

import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

/// hardware decoder(--hwdec).
///
/// Labels, order and the option set come from `PlayerConsts.hardwareDecodersList`
/// (`pure_live/lib/player/utils/player_consts.dart` `hardwareDecodersList`, the
/// list the mobile decoder page renders).
///
/// The list is still narrowed to the backends the running platform can actually
/// use: an Android TV box has no DirectX/VideoToolbox decoder, so offering one
/// only produced a saved value that the player silently replaced. Every backend
/// that *is* reachable there is offered, including the previously unreachable
/// Vulkan pair.
class DecoderSettingsSectionPage extends ConsumerWidget {
  const DecoderSettingsSectionPage({super.key});

  /// Shared by every platform, in the reference's order.
  static const List<String> _common = ['auto', 'auto-safe', 'auto-copy'];

  /// software-only decode. The mobile page uses a plain switch for this, so the entry
  /// is TV-only and keeps this project's own label.
  static const String _softwareOnly = 'no';

  static const List<String> _android = [
    ..._common,
    'mediacodec',
    'mediacodec-copy',
    'vulkan',
    'vulkan-copy',
    _softwareOnly,
  ];

  /// iOS/macOS has no Vulkan video path and the app's own iOS contract
  /// (`mpvHardwareDecodersForPlatform`) rejects it, so it is not offered here.
  static const List<String> _apple = [..._common, 'videotoolbox', 'videotoolbox-copy', _softwareOnly];

  static const List<String> _windows = [
    ..._common,
    'd3d11va',
    'd3d11va-copy',
    'nvdec',
    'nvdec-copy',
    'vulkan',
    'vulkan-copy',
    'dxva2',
    'dxva2-copy',
    'cuda',
    'cuda-copy',
    _softwareOnly,
  ];

  static const List<String> _linux = [
    ..._common,
    'vaapi',
    'vaapi-copy',
    'vdpau',
    'vdpau-copy',
    'drm',
    'drm-copy',
    'nvdec',
    'nvdec-copy',
    'vulkan',
    'vulkan-copy',
    'cuda',
    'cuda-copy',
    'crystalhd',
    'rkmpp',
    _softwareOnly,
  ];

  static List<String> get _decoderKeys {
    if (Platform.isAndroid) return _android;
    if (Platform.isIOS || Platform.isMacOS) return _apple;
    if (Platform.isWindows) return _windows;
    return _linux;
  }

  String _label(String key, String languageCode) {
    if (key == _softwareOnly) return i18n('ui_software_decoding_only');
    return PlayerConsts.optionLabelFor(PlayerConsts.hardwareDecodersList, key, languageCode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final String languageCode = Localizations.localeOf(context).languageCode;
    final List<String> keys = _decoderKeys;

    // A decoder saved on another platform (or an older build) is not in this
    // list; show the first entry instead of crashing, and let the next change
    // write a value this platform supports.
    final int storedIndex = keys.indexOf(playerState.videoHardwareDecoder);
    final String currentKey = storedIndex == -1 ? keys.first : keys[storedIndex];

    // The options ARE the page. It used to show a single row named after the
    // page that opened a selection dialog, so entering it looked like a repeat
    // of the row you just pressed.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('hardware_decoder')),
        if (!playerState.customPlayerOutput)
          Padding(
            // custom driver & hardware accel (kernel page) is what puts --hwdec on the mpv
            // command line; without it this choice is ignored.
            padding: EdgeInsets.only(left: 8.sp, bottom: 8.sp, right: 8.sp),
            child: Text(
              i18nOr('ui_takes_effect_only_with_custom_player_output', i18n('custom_output_hwdec')),
              style: AppTextStyles.t16W500.copyWith(color: context.tvTheme.secondaryTextColor),
            ),
          ),
        TvSettingsCard(
          children: [
            for (final String key in keys)
              TvSettingsNavTile(
                title: _label(key, languageCode),
                icon: key == currentKey ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                trailing: key == currentKey
                    ? Icon(Icons.check_rounded, size: 26.sp, color: context.tvTheme.focusColor)
                    : const SizedBox.shrink(),
                onTap: () => player.updateSettings(playerState.copyWith(videoHardwareDecoder: key)),
              ),
          ],
        ),
        SizedBox(height: 24.sp),
      ],
    );
  }
}
