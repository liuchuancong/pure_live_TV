import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';

/// Multi-select fav-folder picker, newBV's FavoriteFolderDialog: the folders
/// arrive already carrying "this video sits in here", the user ticks any set
/// and the page diffs it against that baseline for the one deal call.
Future<Set<int>?> showFavFolderPicker(BuildContext context, List<({int id, String title, bool contained})> folders) {
  return TvDialogUtils.show<Set<int>>(context: context, builder: (dialogContext) => _FavFolderDialog(folders: folders));
}

class _FavFolderDialog extends StatefulWidget {
  const _FavFolderDialog({required this.folders});

  final List<({int id, String title, bool contained})> folders;

  @override
  State<_FavFolderDialog> createState() => _FavFolderDialogState();
}

class _FavFolderDialogState extends State<_FavFolderDialog> {
  late final Set<int> _selected = {for (final folder in widget.folders) if (folder.contained) folder.id};

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: i18n('video_fav_dialog_title'),
      width: 720.ts(context),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () => Navigator.of(context).pop(_selected),
      onCancel: () => Navigator.of(context).pop(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 480.ts(context)),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.folders.length,
          itemBuilder: (context, index) {
            final folder = widget.folders[index];
            final checked = _selected.contains(folder.id);
            return TvFocusable(
              onTap: () => setState(() => checked ? _selected.remove(folder.id) : _selected.add(folder.id)),
              builder: (context, focused, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: EdgeInsets.only(bottom: 8.sp),
                padding: EdgeInsets.symmetric(horizontal: 16.ts(context), vertical: 12.ts(context)),
                decoration: BoxDecoration(
                  color: checked ? context.tvTheme.focusColor.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14.ts(context)),
                  border: Border.all(color: focused ? context.tvTheme.focusColor : Colors.transparent, width: 2.ts(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 24.ts(context),
                      color: checked ? context.tvTheme.focusColor : Colors.white54,
                    ),
                    SizedBox(width: 12.ts(context)),
                    Expanded(
                      child: Text(
                        folder.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The 分P grid dialog the reference app opens once an archive has more parts
/// than the inline row should show: 20 per page, "P{start}-{end}" tabs, tap a
/// cell and the page starts the queue at that part.
Future<int?> showPartsGridDialog(BuildContext context, {required List<MusicTrack> tracks, required int initialIndex}) {
  return TvDialogUtils.show<int>(
    context: context,
    builder: (dialogContext) => _PartsGridDialog(tracks: tracks, initialIndex: initialIndex),
  );
}

class _PartsGridDialog extends StatefulWidget {
  const _PartsGridDialog({required this.tracks, required this.initialIndex});

  final List<MusicTrack> tracks;
  final int initialIndex;

  static const int pageSize = 20;

  @override
  State<_PartsGridDialog> createState() => _PartsGridDialogState();
}

class _PartsGridDialogState extends State<_PartsGridDialog> {
  late int _page = widget.initialIndex ~/ _PartsGridDialog.pageSize;

  @override
  Widget build(BuildContext context) {
    final accent = context.tvTheme.focusColor;
    final total = widget.tracks.length;
    final pages = (total / _PartsGridDialog.pageSize).ceil();
    final start = _page * _PartsGridDialog.pageSize;
    final slice = widget.tracks.skip(start).take(_PartsGridDialog.pageSize).toList();

    return TvDialog(
      title: '${i18n('music_tracks_title')}（$total）',
      width: 980.ts(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pages > 1)
            Padding(
              padding: EdgeInsets.only(bottom: 16.ts(context)),
              child: Wrap(
                spacing: 10.ts(context),
                runSpacing: 8.ts(context),
                children: [
                  for (var page = 0; page < pages; page++)
                    TvButton(
                      title:
                          'P${page * _PartsGridDialog.pageSize + 1}-${(page + 1) * _PartsGridDialog.pageSize > total ? total : (page + 1) * _PartsGridDialog.pageSize}',
                      size: TvButtonSize.mini,
                      isSecondary: page != _page,
                      onTap: () => setState(() => _page = page),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 460.ts(context),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10.ts(context),
                crossAxisSpacing: 10.ts(context),
                childAspectRatio: 2.4,
              ),
              itemCount: slice.length,
              itemBuilder: (context, index) {
                final globalIndex = start + index;
                final track = slice[index];
                return TvFocusable(
                  autofocus: globalIndex == widget.initialIndex,
                  onTap: () => Navigator.of(context).pop(globalIndex),
                  builder: (context, focused, child) => AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: EdgeInsets.symmetric(horizontal: 12.ts(context), vertical: 8.ts(context)),
                    decoration: BoxDecoration(
                      color: focused ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.ts(context)),
                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'P${globalIndex + 1}',
                          style: AppTextStyles.t14.copyWith(
                            fontWeight: FontWeight.w600,
                            color: focused ? accent : Colors.white70,
                          ),
                        ),
                        Text(
                          track.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
