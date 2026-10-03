part of 'video_search_page.dart';

/// The full-type search section, newBV's search screen for TV: hotwords and
/// recent searches while idle, suggestions while typing, then
/// video / user / movie / live results per keyword, with the sort+duration
/// filter on the video tab.
class VideoSearchSection extends ConsumerStatefulWidget {
  const VideoSearchSection({super.key});

  @override
  ConsumerState<VideoSearchSection> createState() => _VideoSearchSectionState();
}

class _VideoSearchSectionState extends ConsumerState<VideoSearchSection> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, PagingParam<MusicArchive>> _videoParams = {};

  /// Survives the idle→results swap; focus is parked here after a submit so the
  /// remote isn't dead while the (async) result grid builds.
  final FocusNode _searchButtonNode = FocusNode(debugLabel: 'video_search/button');
  String _keyword = '';
  int _typeIndex = 0;
  String _order = 'totalrank';
  int _duration = 0;
  List<Hotword> _hotwords = [];
  List<String> _suggestions = [];
  Timer? _suggestTimer;
  int _suggestSeq = 0;

  static const _typeLabels = [
    ('video_search_type_video', Icons.movie_outlined),
    ('video_search_type_user', Icons.person_outline_rounded),
    ('video_search_type_pgc', Icons.live_tv_outlined),
    ('video_search_type_live', Icons.sensors_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _loadHotwords();
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
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

  void _onTextChanged() {
    _suggestTimer?.cancel();
    final term = _controller.text.trim();
    if (term.isEmpty) {
      _suggestSeq++;
      setState(() => _suggestions = []);
      return;
    }
    _suggestTimer = Timer(const Duration(milliseconds: 350), () => _loadSuggestions(term));
  }

  Future<void> _loadSuggestions(String term) async {
    final seq = ++_suggestSeq;
    try {
      final items = await BilibiliUgcApi.instance.getSuggestions(term);
      if (!mounted || seq != _suggestSeq || _controller.text.trim() != term) return;
      setState(() => _suggestions = items.where((s) => s.trim().isNotEmpty).take(8).toList());
    } catch (_) {}
  }

  void _submit(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    _suggestTimer?.cancel();
    _suggestSeq++;
    ref.read(videoSearchHistoryControllerProvider.notifier).add(trimmed);
    setState(() {
      _keyword = trimmed;
      _suggestions = [];
    });
    // The chip/field that triggered this unmounts with the idle view; park
    // focus on the surviving search button so the remote stays live.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_searchButtonNode.hasFocus) _searchButtonNode.requestFocus();
    });
  }

  Future<void> _openFilter() async {
    final picked = await showVideoSearchFilterDialog(context, order: _order, duration: _duration);
    if (picked == null || !mounted) return;
    setState(() {
      _order = picked.order;
      _duration = picked.duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showingSuggestions = _suggestions.isNotEmpty && _controller.text.trim() != _keyword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.ts(context), 16.ts(context), 24.ts(context), 8.ts(context)),
          child: Row(
            children: [
              SizedBox(
                width: 480.ts(context),
                child: TvInputField(
                  controller: _controller,
                  hint: i18n('video_search_hint'),
                  height: 64.ts(context),
                  maxLines: 1,
                  onSubmitted: _submit,
                ),
              ),
              SizedBox(width: 16.ts(context)),
              TvButton(
                title: i18n('search_live'),
                icon: Icon(Icons.search_rounded, size: 28.ts(context)),
                size: TvButtonSize.mini,
                focusNode: _searchButtonNode,
                onTap: () => _submit(_controller.text),
              ),
              if (_keyword.isNotEmpty && _typeIndex == 0) ...[
                SizedBox(width: 12.ts(context)),
                TvButton(
                  key: const ValueKey('search_filter'),
                  title: i18n('video_search_filter'),
                  icon: Icon(Icons.filter_list_rounded, size: 22.ts(context)),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: _openFilter,
                ),
              ],
              if (_keyword.isNotEmpty) ...[
                SizedBox(width: 20.ts(context)),
                for (final (index, (label, icon)) in _typeLabels.indexed) ...[
                  TvButton(
                    key: ValueKey('search_type_$index'),
                    title: i18n(label),
                    icon: Icon(icon, size: 22.ts(context)),
                    size: TvButtonSize.mini,
                    isSecondary: _typeIndex != index,
                    onTap: () => setState(() => _typeIndex = index),
                  ),
                  SizedBox(width: 10.ts(context)),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: switch (showingSuggestions) {
            true => _buildSuggestions(),
            false when _keyword.isEmpty => _buildIdle(),
            false => _buildResults(),
          },
        ),
      ],
    );
  }

  Widget _buildIdle() {
    final history = ref.watch(videoSearchHistoryControllerProvider);
    if (history.isEmpty) return VideoHotwordBoard(hotwords: _hotwords, onPick: _submit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.ts(context), 4.ts(context), 24.ts(context), 0),
          child: Text(
            '${i18n('search_history')}（${i18n('history_long_press_delete')}）',
            style: AppTextStyles.t20.copyWith(color: context.tvTheme.focusColor),
          ),
        ),
        SizedBox(height: 10.ts(context)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.ts(context)),
          child: Wrap(
            spacing: 12.ts(context),
            runSpacing: 10.ts(context),
            children: [
              for (final keyword in history)
                TvFocusable(
                  key: Key('video_history_$keyword'),
                  onTap: () {
                    _controller.text = keyword;
                    _submit(keyword);
                  },
                  onLongPress: () => ref.read(videoSearchHistoryControllerProvider.notifier).remove(keyword),
                  builder: (context, focused, child) => AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 44.ts(context),
                    padding: EdgeInsets.symmetric(horizontal: 22.ts(context)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: focused ? context.tvTheme.focusColor : context.tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(22.ts(context)),
                      border: Border.all(color: context.tvTheme.focusColor, width: focused ? 2.5.ts(context) : 1.5.ts(context)),
                    ),
                    child: Text(
                      keyword,
                      style: AppTextStyles.t16.copyWith(
                        color: focused ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              TvFocusable(
                key: const Key('video_history_clear'),
                onTap: () => ref.read(videoSearchHistoryControllerProvider.notifier).clear(),
                builder: (context, focused, child) => AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 44.ts(context),
                  padding: EdgeInsets.symmetric(horizontal: 22.ts(context)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: focused ? context.tvTheme.focusColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(22.ts(context)),
                    border: Border.all(
                      color: focused ? context.tvTheme.focusColor : Colors.white30,
                      width: 1.5.ts(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20.ts(context), color: focused ? Colors.black : Colors.white70),
                      SizedBox(width: 8.ts(context)),
                      Text(
                        i18n('clear_search_history'),
                        style: AppTextStyles.t16.copyWith(
                          color: focused ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: VideoHotwordBoard(hotwords: _hotwords, onPick: _submit)),
      ],
    );
  }

  Widget _buildSuggestions() {
    final tvTheme = context.tvTheme;
    return ListView.builder(
      padding: EdgeInsets.all(24.ts(context)),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return TvFocusable(
          key: Key('video_suggest_$suggestion'),
          onTap: () {
            _controller.text = suggestion;
            _submit(suggestion);
          },
          builder: (context, focused, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: EdgeInsets.only(bottom: 8.ts(context)),
            padding: EdgeInsets.symmetric(horizontal: 20.ts(context), vertical: 14.ts(context)),
            decoration: BoxDecoration(
              color: focused ? tvTheme.focusColor.withValues(alpha: 0.18) : tvTheme.cardColor,
              borderRadius: BorderRadius.circular(14.ts(context)),
              border: Border.all(color: focused ? tvTheme.focusColor : Colors.transparent, width: 2.ts(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 22.ts(context), color: tvTheme.secondaryTextColor),
                SizedBox(width: 14.ts(context)),
                Expanded(
                  child: Text(
                    suggestion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t18.copyWith(color: tvTheme.primaryTextColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults() {
    switch (_typeIndex) {
      case 1:
        return VideoUserResults(key: ValueKey(_keyword), keyword: _keyword);
      case 2:
        return VideoPgcResults(key: ValueKey(_keyword), keyword: _keyword);
      case 3:
        return VideoLiveResults(key: ValueKey(_keyword), keyword: _keyword);
      default:
        final themeState = ref.watch(themeSettingsControllerProvider);
        final paramKey = '$_keyword|$_order|$_duration';
        final param = _videoParams.putIfAbsent(
          paramKey,
          () => PagingParam<MusicArchive>(
            mode: PagingMode.serverRemote,
            pageSize: 20,
            keepAlive: true,
            fetchRemote: (page, size) => BilibiliMusicApi.instance.searchVideos(
              _keyword,
              page: page,
              pageSize: size,
              order: _order,
              duration: _duration,
            ),
          ),
        );
        return BasePagedTvView<MusicArchive>(
          key: ValueKey('video_search_$paramKey'),
          param: param,
          getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
          gridDelegate: TvAdaptiveGrid.media(
            context,
            crossAxisCount: themeState.denseRoomLayout,
            mainAxisSpacing: themeState.mainAxisSpacing.w,
            crossAxisSpacing: themeState.crossAxisSpacing.w,
            childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
          ),
          itemBuilder: (context, archive, index) =>
              VideoCard(archive: archive, onTap: () => openVideoArchive(context, ref, archive)),
        );
    }
  }
}
