import 'package:flutter/material.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/theme/styles/app_styles.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/home/widgets/tv_diaital_clock.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<Map<String, dynamic>> _navigationMenus = [
    {'title': '直播关注', 'icon': Icons.favorite_border},
    {'title': '热门直播', 'icon': Icons.local_fire_department_outlined},
    {'title': '分区类别', 'icon': Icons.apps_rounded},
    {'title': '关注分区', 'icon': Icons.view_module_rounded},
    {'title': '链接放映', 'icon': Icons.movie_creation_outlined},
    {'title': '搜索直播', 'icon': Icons.search_rounded},
    {'title': '观看记录', 'icon': Icons.history},
  ];

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [AppStyle.vGap32, _buildHeader(), const Spacer(), _buildMainContent(), AppStyle.vGap32],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppStyle.hGap48,
        Text("纯粹直播", style: AppTextStyles.t32W600),
        AppStyle.hGap24,
        const Spacer(),
        TvDigitalClock(style: AppTextStyles.t32W600),
        AppStyle.hGap48,
      ],
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64.sp,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _navigationMenus.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final menu = _navigationMenus[index];

                return TvButton(
                  autofocus: index == 0,
                  title: menu['title'] as String,
                  icon: Icon(menu['icon'] as IconData),
                  size: TvButtonSize.large,
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
