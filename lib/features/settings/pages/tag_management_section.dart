import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/tag_management/tag_management_controller.dart';

/// Tag management: create tags and remove them. Room assignment happens from
/// the room card long-press action, which writes the same controller.
class TagManagementSectionPage extends ConsumerStatefulWidget {
  const TagManagementSectionPage({super.key});

  @override
  ConsumerState<TagManagementSectionPage> createState() => TagManagementSectionPageState();
}

class TagManagementSectionPageState extends ConsumerState<TagManagementSectionPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _addTag() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _result = i18n('ui_parameter_error'));
      return;
    }
    ref.read(tagManagementControllerProvider.notifier).addTag(name, _description.text.trim());
    _name.clear();
    _description.clear();
    setState(() => _result = i18n('save_success'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagManagementControllerProvider);
    final tag = ref.read(tagManagementControllerProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: RemoteSyncQrCard(width: 280)),
          SizedBox(height: 20.sp),
          // 标签管理
          TvSettingsGroupTitle(title: i18n('tag_management')),
          TvSettingsCard(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TvInputField(controller: _name, hint: i18n('tag_name_label')),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TvInputField(controller: _description, hint: i18n('tag_description_label')),
              ),
              TvSettingsOptionTile(
                title: i18n('ui_add'),
                icon: Icons.add_rounded,
                options: [i18n('ui_add')],
                index: 0,
                onChanged: (_) => _addTag(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              for (var i = 0; i < state.tags.length; i++)
                TvSettingsOptionTile(
                  title: state.tags[i].name,
                  subtitle: state.tags[i].description.isEmpty ? null : state.tags[i].description,
                  icon: Icons.sell_outlined,
                  options: [i18n('delete')],
                  index: 0,
                  onChanged: (_) => tag.deleteTag(i),
                ),
            ],
          ),
          if (_result.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(_result, style: TextStyle(fontSize: 14.sp, color: context.tvTheme.focusColor)),
            ),
        ],
      ),
    );
  }
}
