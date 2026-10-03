import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// Search over the video site, grid results like the other discovery views.
class MusicSearchPage extends ConsumerStatefulWidget {
  const MusicSearchPage({super.key});

  @override
  ConsumerState<MusicSearchPage> createState() => MusicSearchPageState();
}

class MusicSearchPageState extends ConsumerState<MusicSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, PagingParam<MusicArchive>> _params = {};

  /// Survives the idle→results swap; focus parks here after a submit so the
  /// remote stays live while the async result grid builds.
  final FocusNode _searchButtonNode = FocusNode(debugLabel: 'music_search/button');
  String _submittedKeyword = '';
  List<Hotword> _hotwords = [];

  @override
  void initState() {
    super.initState();
    _loadHotwords();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchButtonNode.dispose();
    super.dispose();
  }

  Future<void> _loadHotwords() async {
    try {
      final words = await BilibiliUgcApi.instance.getHotwords();
      if (!mounted) return;
      setState(() => _hotwords = words);
    } catch (_) {}
  }

  void _submit(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    setState(() => _submittedKeyword = trimmed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_searchButtonNode.hasFocus) _searchButtonNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final themeState = ref.watch(themeSettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.ts(context), 16.ts(context), 20.ts(context), 8.ts(context)),
          child: Row(
            children: [
              SizedBox(
                width: 520.ts(context),
                child: TvInputField(
                  controller: _controller,
                  hint: i18n('music_search_hint'),
                  height: 64.ts(context),
                  maxLines: 1,
                  onSubmitted: _submit,
                ),
              ),
              SizedBox(width: 16.ts(context)),
              TvButton(
                title: i18n('music_tab_search'),
                icon: Icon(Icons.search_rounded, size: 28.ts(context)),
                size: TvButtonSize.mini,
                focusNode: _searchButtonNode,
                onTap: () => _submit(_controller.text),
              ),
            ],
          ),
        ),
        Expanded(
          child: _submittedKeyword.isEmpty
              ? DpadRegion(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.ts(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hotwords.isEmpty)
                          Center(
                            child: Text(
                              i18n('music_search_empty_hint'),
                              style: AppTextStyles.t18.copyWith(
                                fontWeight: FontWeight.w500,
                                color: tvTheme.secondaryTextColor,
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 26.ts(context), color: accent),
                              SizedBox(width: 8.ts(context)),
                              Text(
                                i18n('video_search_hotwords'),
                                style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.ts(context)),
                          Wrap(
                            spacing: 12.ts(context),
                            runSpacing: 12.ts(context),
                            children: [
                              for (final (index, word) in _hotwords.indexed)
                                TvFocusable(
                                  autofocus: index == 0,
                                  onTap: () => _submit(word.keyword),
                                  builder: (context, focused, child) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    padding: EdgeInsets.symmetric(horizontal: 20.ts(context), vertical: 10.ts(context)),
                                    decoration: BoxDecoration(
                                      color: tvTheme.cardColor,
                                      borderRadius: BorderRadius.circular(24.ts(context)),
                                      border: Border.all(
                                        color: focused ? accent : Colors.transparent,
                                        width: 2.ts(context),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${index + 1}',
                                          style: AppTextStyles.t14.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: index < 3 ? Colors.redAccent : tvTheme.secondaryTextColor,
                                          ),
                                        ),
                                        SizedBox(width: 8.ts(context)),
                                        Text(
                                          word.keyword,
                                          style: AppTextStyles.t16.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: tvTheme.primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final keyword = _submittedKeyword;
                    final param = _params.putIfAbsent(
                      keyword,
                      () => PagingParam<MusicArchive>(
                        mode: PagingMode.serverRemote,
                        pageSize: 20,
                        keepAlive: true,
                        fetchRemote: (page, size) =>
                            BilibiliMusicApi.instance.searchVideos(keyword, page: page, pageSize: size),
                      ),
                    );
                    return BasePagedTvView<MusicArchive>(
                      key: ValueKey('music_search_$keyword'),
                      param: param,
                      getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
                      gridDelegate: TvAdaptiveGrid.media(
                        context,
                        crossAxisCount: themeState.denseRoomLayout,
                        mainAxisSpacing: themeState.mainAxisSpacing.w,
                        crossAxisSpacing: themeState.crossAxisSpacing.w,
                        childAspectRatio:
                            ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
                      ),
                      itemBuilder: (context, archive, index) =>
                          MusicVideoCard(archive: archive, onTap: () => MusicArchiveRoute(archive).push(context)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
