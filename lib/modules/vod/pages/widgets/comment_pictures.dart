import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// The strip of image attachments a comment carries (newBV's CommentsDialog
/// picture row): a Wrap of focusable thumbnails, each opening the full-screen
/// viewer. Empty lists render nothing, so callers drop it in unconditionally.
class CommentPicturesRow extends StatelessWidget {
  const CommentPicturesRow({super.key, required this.urls, this.thumbnail = 80, this.autofocus = false});

  final List<String> urls;
  final double thumbnail;

  /// Only the first thumbnail across a list should grab the keyboard; the
  /// panel flags just the leading comment's row.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final side = thumbnail.ts(context);

    return Padding(
      padding: EdgeInsets.only(top: 6.ts(context)),
      child: Wrap(
        spacing: 6.ts(context),
        runSpacing: 6.ts(context),
        children: [
          for (final (index, url) in urls.indexed)
            TvFocusable(
              autofocus: autofocus && index == 0,
              onTap: () => showCommentImageViewer(context, urls, index),
              builder: (context, focused, _) => Container(
                width: side,
                height: side,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: tvTheme.cardColor,
                  borderRadius: BorderRadius.circular(8.ts(context)),
                  border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                ),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.broken_image_outlined, size: side * 0.5, color: tvTheme.secondaryTextColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens [urls] full-screen at [initial] (newBV's CommentImageOverlay). The
/// viewer keeps the d-pad inside a dialog region so the page behind it (the
/// comment list, or the player) cannot steal the walk.
void showCommentImageViewer(BuildContext context, List<String> urls, int initial) {
  if (urls.isEmpty) return;
  TvDialogUtils.show<void>(context: context, builder: (_) => _CommentImageViewer(urls: urls, initial: initial));
}

class _CommentImageViewer extends StatefulWidget {
  const _CommentImageViewer({required this.urls, required this.initial});

  final List<String> urls;
  final int initial;

  @override
  State<_CommentImageViewer> createState() => _CommentImageViewerState();
}

class _CommentImageViewerState extends State<_CommentImageViewer> {
  late int _index = widget.initial.clamp(0, widget.urls.length - 1);

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final multiple = widget.urls.length > 1;

    return Material(
      color: Colors.black.withValues(alpha: 0.94),
      child: DpadRegion(
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: TvDialogFocusGuard(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.all(20.ts(context)),
                  child: TvIconButton(
                    icon: const Icon(Icons.close_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    autofocus: !multiple,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 64.ts(context)),
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.urls[_index],
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => Icon(
                        Icons.broken_image_outlined,
                        size: 72.ts(context),
                        color: tvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(28.ts(context)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (multiple) ...[
                      TvIconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        size: TvIconButtonSize.medium,
                        isSecondary: true,
                        autofocus: true,
                        onTap: _index > 0 ? () => setState(() => _index--) : null,
                      ),
                      SizedBox(width: 32.ts(context)),
                    ],
                    Text(
                      '${_index + 1} / ${widget.urls.length}',
                      style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                    ),
                    if (multiple) ...[
                      SizedBox(width: 32.ts(context)),
                      TvIconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        size: TvIconButtonSize.medium,
                        isSecondary: true,
                        onTap: _index < widget.urls.length - 1 ? () => setState(() => _index++) : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
