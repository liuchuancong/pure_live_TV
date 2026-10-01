import 'package:pure_live/exports/exports.dart';

/// newBV's search filter sheet: one sort chip group and one duration chip
/// group; confirm hands the pair back, cancel returns null and keeps whatever
/// the page already had.
Future<({String order, int duration})?> showVideoSearchFilterDialog(
  BuildContext context, {
  required String order,
  required int duration,
}) {
  return TvDialogUtils.show<({String order, int duration})>(
    context: context,
    builder: (_) => _SearchFilterDialog(order: order, duration: duration),
  );
}

class _SearchFilterDialog extends StatefulWidget {
  const _SearchFilterDialog({required this.order, required this.duration});

  final String order;
  final int duration;

  static const orders = [
    ('totalrank', 'video_search_order_totalrank'),
    ('click', 'video_search_order_click'),
    ('pubdate', 'video_search_order_pubdate'),
    ('dm', 'video_search_order_dm'),
    ('stow', 'video_search_order_stow'),
  ];
  static const durations = [
    (0, 'video_search_duration_all'),
    (1, 'video_search_duration_lt10'),
    (2, 'video_search_duration_10_30'),
    (3, 'video_search_duration_30_60'),
    (4, 'video_search_duration_gt60'),
  ];

  @override
  State<_SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<_SearchFilterDialog> {
  late String _order = widget.order;
  late int _duration = widget.duration;

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: i18n('video_search_filter'),
      width: 860.ts(context),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () => Navigator.of(context).pop((order: _order, duration: _duration)),
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(i18n('video_search_group_order'), style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 12.ts(context)),
          _chipGroup(
            children: [
              for (final (value, label) in _SearchFilterDialog.orders)
                _chip(label: i18n(label), active: _order == value, onTap: () => setState(() => _order = value)),
            ],
          ),
          SizedBox(height: 24.ts(context)),
          Text(i18n('video_search_group_duration'), style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 12.ts(context)),
          _chipGroup(
            children: [
              for (final (value, label) in _SearchFilterDialog.durations)
                _chip(label: i18n(label), active: _duration == value, onTap: () => setState(() => _duration = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipGroup({required List<Widget> children}) => Wrap(
      spacing: 10.ts(context),
      runSpacing: 10.ts(context),
      children: children,
    );

  Widget _chip({required String label, required bool active, required VoidCallback onTap}) {
    final accent = context.tvTheme.focusColor;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 20.ts(context), vertical: 12.ts(context)),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30.ts(context)),
          border: Border.all(color: focused || active ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Text(
          label,
          style: AppTextStyles.t16.copyWith(
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? accent : Colors.white,
          ),
        ),
      ),
    );
  }
}
