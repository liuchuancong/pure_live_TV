import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/styles/styles.dart';
import 'package:pure_live/services/tag_management/live_tag.dart';
import 'package:pure_live/services/tag_management/tag_management_controller.dart';

/// Tag management: tags are created through an add dialog (name + optional
/// description) and shown as a chip cloud — a Wrap of buttons, one per tag.
/// Pressing a chip opens the tag detail dialog, which is where deletion
/// lives. Room assignment happens from the room card long-press action, which
/// writes the same controller.
class TagManagementSectionPage extends ConsumerStatefulWidget {
  const TagManagementSectionPage({super.key});

  @override
  ConsumerState<TagManagementSectionPage> createState() => TagManagementSectionPageState();
}

class TagManagementSectionPageState extends ConsumerState<TagManagementSectionPage> {
  String _result = '';

  Future<void> _addTag() async {
    final added = await TvDialogUtils.show<bool>(context: context, builder: (_) => const _AddTagDialog());
    if (added == true && mounted) setState(() => _result = i18n('save_success'));
  }

  Future<void> _showTagDetail(LiveTag tag, int index) async {
    await TvDialogUtils.show(
      context: context,
      builder: (dialogContext) => _TagDetailDialog(
        tag: tag,
        onDelete: () {
          Navigator.of(dialogContext).pop();
          ref.read(tagManagementControllerProvider.notifier).deleteTag(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagManagementControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: RemoteSyncQrCard(width: 280)),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('tag_management')),
          TvSettingsCard(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: state.tags.isEmpty
                    ? SizedBox(
                        height: 160.h,
                        child: AppStatusView(
                          type: AppStatusType.empty,
                          title: i18nOr('tag_empty_title', '暂无标签'),
                          subtitle: i18n('tag_management_subtitle'),
                          isMini: true,
                          icon: Icons.sell_outlined,
                        ),
                      )
                    : Wrap(
                        spacing: 12.sp,
                        runSpacing: 12.sp,
                        children: [
                          for (var i = 0; i < state.tags.length; i++)
                            TvButton(
                              title: state.tags[i].name,
                              icon: const Icon(Icons.sell_outlined),
                              size: TvButtonSize.small,
                              onTap: () => _showTagDetail(state.tags[i], i),
                            ),
                        ],
                      ),
              ),
              TvSettingsNavTile(title: i18n('ui_add'), icon: Icons.add_rounded, onTap: _addTag),
            ],
          ),
          if (_result.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(
                _result,
                style: TextStyle(fontSize: 14.sp, color: context.tvTheme.focusColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// The add dialog: tag name (required) + optional description, validated in
/// place — empty and duplicate names show an error line instead of closing.
class _AddTagDialog extends ConsumerStatefulWidget {
  const _AddTagDialog();

  @override
  ConsumerState<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends ConsumerState<_AddTagDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameFocus.requestFocus();
      // Same trick as TvInputDialog: a dialog exists to be typed into, so the
      // name field goes straight into editing via its own Select key handler
      // instead of waiting for another OK.
      final FocusOnKeyEventCallback? onKey = _nameFocus.onKeyEvent;
      onKey?.call(
        _nameFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.select,
          logicalKey: LogicalKeyboardKey.select,
          timeStamp: Duration.zero,
        ),
      );
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = i18n('tag_name_empty_error'));
      return;
    }
    // The dialog sits above the page's scope, so reach the container through
    // the context instead of `controller.state` (a riverpod-protected member).
    final container = ProviderScope.containerOf(context);
    final duplicate = container
        .read(tagManagementControllerProvider)
        .tags
        .any((t) => t.name.toLowerCase() == name.toLowerCase());
    if (duplicate) {
      setState(() => _error = i18n('tag_invalid_or_duplicate'));
      return;
    }
    container.read(tagManagementControllerProvider.notifier).addTag(name, _description.text.trim());
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return TvDialog(
      title: i18n('ui_add'),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: _submit,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvInputField(controller: _name, focusNode: _nameFocus, hint: i18n('tag_input_hint')),
            SizedBox(height: 12.sp),
            TvInputField(controller: _description, hint: i18n('tag_desc_hint')),
            if (_error.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10.sp),
                child: Text(
                  _error,
                  style: TextStyle(fontSize: 14.sp, color: tvTheme.focusColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tag detail: the name and its description, with deletion behind the confirm
/// button.
class _TagDetailDialog extends StatelessWidget {
  const _TagDetailDialog({required this.tag, required this.onDelete});

  final LiveTag tag;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return TvDialog(
      title: i18n('tag_detail'),
      confirmText: i18n('delete'),
      cancelText: i18n('cancel'),
      onConfirm: onDelete,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tag.name, style: AppTextStyles.t26W600),
            if (tag.description.isNotEmpty) ...[
              SizedBox(height: 8.sp),
              Text(
                tag.description,
                style: TextStyle(fontSize: 15.sp, color: tvTheme.secondaryTextColor),
              ),
            ],
            SizedBox(height: 16.sp),
            Text(
              i18n('delete_tag_confirm_msg'),
              style: TextStyle(fontSize: 14.sp, color: tvTheme.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
