part of 'ugc_user_space_page.dart';

/// A shared UP-space page: the header card (avatar, sign, followers, follow
/// button) over a paged uploads grid. Music opens it from comment/track
/// authors, video from detail cards — one implementation for both.
class UgcUserSpacePage extends ConsumerStatefulWidget {
  const UgcUserSpacePage({super.key, required this.mid, this.name = ''});

  final int mid;
  final String name;

  @override
  ConsumerState<UgcUserSpacePage> createState() => _UgcUserSpacePageState();
}

class _UgcUserSpacePageState extends ConsumerState<UgcUserSpacePage> {
  final ScrollController _scroll = ScrollController();
  UserSpaceInfo? _info;
  final List<MusicArchive> _uploads = [];
  bool _loadingHeader = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  bool _followBusy = false;
  String _order = 'pubdate';

  @override
  void initState() {
    super.initState();
    _loadHeader();
    _loadMore();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 && !_loadingMore && _hasMore) _loadMore();
  }

  Future<void> _loadHeader() async {
    try {
      final info = await BilibiliUgcApi.instance.getUserSpace(widget.mid);
      if (!mounted) return;
      setState(() {
        _info = info;
        _loadingHeader = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingHeader = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final uploads = await BilibiliUgcApi.instance.getUserUploads(widget.mid, page: _page + 1, order: _order);
      if (!mounted) return;
      setState(() {
        _uploads.addAll(uploads);
        _page += 1;
        _hasMore = uploads.length >= 25;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    try {
      await BilibiliUgcApi.instance.setFollowing(widget.mid, follow: !(_info?.isFollowed ?? false));
      if (!mounted) return;
      setState(
        () => _info = UserSpaceInfo(
          mid: _info!.mid,
          name: _info!.name,
          face: _info!.face,
          sign: _info!.sign,
          followers: _info!.followers,
          following: _info!.following,
          videoCount: _info!.videoCount,
          isFollowed: !_info!.isFollowed,
          level: _info!.level,
        ),
      );
      ToastUtil.show(_info!.isFollowed ? i18n('video_follow_done') : i18n('video_unfollow_done'));
    } catch (_) {
      ToastUtil.show(i18n('video_action_need_login'));
    } finally {
      _followBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvPageScaffold(
      title: _info?.name ?? widget.name,
      child: _loadingHeader
          ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
          : _error != null && _info == null
          ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error)
          : DpadRegion(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(
                    child: UgcSpaceHeaderCard(info: _info!, onToggleFollow: _toggleFollow),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: 12.sp)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.ts(context)),
                      child: Row(
                        children: [
                          Text(
                            '${i18n('video_uploads_title')}（${_info!.videoCount}）',
                            style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                          ),
                          const Spacer(),
                          TvButton(
                            title: i18n(_order == 'pubdate' ? 'video_order_newest' : 'video_order_most_played'),
                            icon: Icon(
                              _order == 'pubdate' ? Icons.schedule_rounded : Icons.local_fire_department_outlined,
                              size: 22.ts(context),
                            ),
                            size: TvButtonSize.mini,
                            isSecondary: true,
                            onTap: () {
                              setState(() {
                                _order = _order == 'pubdate' ? 'click' : 'pubdate';
                                _uploads.clear();
                                _page = 0;
                                _hasMore = true;
                              });
                              _loadMore();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: 12.sp)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24.ts(context)),
                    sliver: SliverGrid(
                      gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                      delegate: SliverChildBuilderDelegate(childCount: _uploads.length + (_hasMore ? 1 : 0), (
                        context,
                        index,
                      ) {
                        if (index >= _uploads.length) {
                          return Center(
                            child: _loadingMore
                                ? SizedBox(
                                    width: 32.ts(context),
                                    height: 32.ts(context),
                                    child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }
                        final upload = _uploads[index];
                        return UgcSpaceUploadCard(archive: upload, mid: widget.mid);
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
