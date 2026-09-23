import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';

/// The picture area while a session plays audio only.
///
/// Takes the place of the video surface: the room's avatar stands in for the
/// stream, with its own copy scaled up behind it as a backdrop. The video
/// widget stays mounted underneath (it is only hidden), so restoring video does
/// not have to rebuild the engine's texture.
///
/// Nothing here is focusable - the play page owns every remote key - and the
/// only animation is a slow pulse on the avatar, which is driven by an
/// [AnimationController] so it stops with the surface.
class AudioOnlySurface extends StatefulWidget {
  const AudioOnlySurface({super.key, required this.room});

  /// The room being listened to, when it is known yet.
  final LiveRoom? room;

  @override
  State<AudioOnlySurface> createState() => _AudioOnlySurfaceState();
}

class _AudioOnlySurfaceState extends State<AudioOnlySurface> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.97, end: 1.03).animate(
    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final LiveRoom? room = widget.room;
    final String? avatar = room?.avatar;
    final bool hasAvatar = avatar != null && avatar.isNotEmpty;

    final String title = (room?.title ?? '').trim().isNotEmpty
        ? room!.title.trim()
        : i18n('untitled_room');

    // Compact under 500 logical pixels of height, which is where the panel
    // otherwise crowds the room-info bar and the control bar.
    final bool compact = MediaQuery.sizeOf(context).height < 500;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop: the room colour, the avatar as a dimmed wash, then a
        // gradient so the centre content keeps its contrast on any palette.
        ColoredBox(color: tvTheme.backgroundColor),
        if (hasAvatar)
          Opacity(
            opacity: 0.20,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(tvTheme.cardColor.withValues(alpha: 0.55), BlendMode.srcATop),
              child: CachedNetworkImage(
                imageUrl: avatar,
                cacheManager: CustomImageCacheManager.instance,
                memCacheWidth: 320,
                maxWidthDiskCache: 640,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tvTheme.backgroundColor.withValues(alpha: 0.86),
                tvTheme.backgroundColor.withValues(alpha: 0.62),
                tvTheme.backgroundColor.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: EdgeInsets.all(6.sp),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.55), width: 2.sp),
                    ),
                    child: TvCommonAvatar(
                      avatarUrl: avatar,
                      fallbackName: room?.nick,
                      radius: compact ? 56.sp : 76.sp,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 20.sp : 32.sp),
                Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t28W600.copyWith(color: tvTheme.primaryTextColor),
                ),
                if ((room?.nick ?? '').isNotEmpty) ...[
                  SizedBox(height: 10.sp),
                  Text(
                    room!.nick,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                ],
                SizedBox(height: compact ? 18.sp : 26.sp),
                _AudioOnlyBadge(compact: compact),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The headphone badge that says why the picture is missing.
class _AudioOnlyBadge extends StatelessWidget {
  const _AudioOnlyBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: tvTheme.cardColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Remix.headphone_line, size: 24.sp, color: tvTheme.focusColor),
          SizedBox(width: 10.sp),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n('ui_audio_only'),
                style: AppTextStyles.t18W500.copyWith(color: tvTheme.primaryTextColor),
              ),
              if (!compact)
                Text(
                  i18n('ui_audio_only_no_video_rendering'),
                  style: AppTextStyles.t14W300.copyWith(color: tvTheme.secondaryTextColor),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
