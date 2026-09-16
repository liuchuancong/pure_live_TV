// Translation helpers.
//
// Runtime lookups use assets/translations through easy_localization, so strings
// follow the language setting. The static table below stays as an offline
// fallback, and i18nOr returns the caller fallback when a key is unknown.
import 'package:easy_localization/easy_localization.dart' as ez;

Map<String, String> _labels = {
  'cc_live_categories': '直播分类',
  'cc_official_entries': '官方房间/专题',
  'huajiao_hot': '公开推荐',
  'huajiao_original_stream': '原始流',
  'inke_media_unavailable': '该房间仍在直播，但当前官网精选未提供已验证的公开播放地址，请稍后刷新。',
  'niconico_access_restricted': '此节目的当前观看权限受限。',
  'niconico_login_required': '此节目要求登录官方站点。',
  'niconico_program_scope': '收藏对应本次节目，主播的新节目需重新添加；弹幕暂未接入。',
  'niconico_region_restricted': '此节目设有地区访问限制。',
  'niconico_scheduled': '节目尚未开始。',
  'openrec_hls_auto': 'HLS 自动',
  'openrec_low_latency': '低延迟流',
  'openrec_multiple_broadcasts': '此频道有多个当前直播，请在原站确认；当前不自动选择其中一个。',
  'openrec_partial_sources': '部分源暂时不可用，当前仅列出已成功解析的画质。',
  'openrec_public_directory': '公开直播',
  'openrec_public_source': '公开流',
  'openrec_restricted': '此直播有访问限制，尚未接入相应观看方式。',
  'picarto_public_directory': '公开直播（不含成人内容）',
  'site_huajiao': '花椒',
  'site_inke': '映客',
  'site_kilakila': '克拉克拉',
  'site_weibo': '微博直播',
  'site_xiaohongshu': '小红书',
  'tting_auto': '自动',
  'tting_public_directory': '首页公开直播',
  'tting_restricted': '此频道标记为受限，公开播放尚不可用',
  'weibo_original_stream': '原始流',
  'weibo_public_directory': '公开推荐',
  'weibo_restricted': '当前场次存在访问限制或播放已关闭；公开直播源不可用。',
  'weibo_room_scope': '收藏跟踪当前直播场次，不是主播账号；新场次需重新导入直播链接。',
  'xiaohongshu_display_viewers': '平台展示观看值：{value}（非已验证的实时在线人数）',
  'xiaohongshu_restricted': '该房间存在访问条件或访问状态待确认，当前没有可用的公开完整直播源。',
  'xiaohongshu_room_scope': '当前以直播房间号跟踪；主播重新开播使用新房间号时，请重新导入分享链接。',
  // —— 通用 ——
  'cancel': '取消',
  'clear_search_history': '清空',
  'confirm': '确定',
  'download_failed': '下载失败',
  'epg_import_failed': '节目单导入失败',
  'epg_source_updated': '节目单源已更新',
  'history_long_press_delete': '长按删除',
  'search_history': '搜索历史',
  'font_danmaku_group': '弹幕字体',
  'font_default_subtitle': '使用应用内置默认字体',
  'font_in_use': '使用中',
  'font_preview_sample': '字体预览：永东体 Aa 123',
  'remote_sync_devices': '局域网设备',
  'remote_sync_no_devices': '尚未发现设备',
  'remote_sync_push': '推送设置',
  'remote_sync_push_done': '已推送到 {name}',
  'remote_sync_push_failed': '推送到 {name} 失败',
  'remote_sync_pull': '按地址拉取设置',
  'remote_sync_pull_subtitle': '输入对方地址后导入其设置',
  'remote_sync_pull_title': '从设备拉取设置',
  'remote_sync_starting': '正在启动局域网同步服务…',
  // —— 背景设置 ——
  'ui_background_settings': '背景设置',
  'background_apply_failed': '设置失败：{msg}',
  'background_catalog_empty': '远端目录为空',
  'background_clear': '清除背景',
  'background_entry_subtitle': '壁纸、动态壁纸、纯色渐变',
  'background_invalid_gradient': '这个渐变数据不完整',
  'background_load_failed': '背景目录加载失败',
  'background_no_category': '该来源暂无数据',
  'background_no_item': '这个分类还没有资源',
  'wallpaper': '壁纸',
  'wallpaper_api_entry_subtitle': '每次打开随机取一张图',
  'wallpaper_api_group': '随机壁纸 API',
  'wallpaper_api_group_count': '{count} 个来源',
  'wallpaper_background_cleared': '背景已清除',
  'wallpaper_category_count': '{count} 张',
  'wallpaper_category_group': '{categories} 个分类',
  'wallpaper_change_image': '换一张',
  'wallpaper_display_group': '显示设置',
  'wallpaper_fetch_failed': '获取图片失败，请重试',
  'wallpaper_fit_contain': '完整包含',
  'wallpaper_fit_cover': '等比覆盖',
  'wallpaper_fit_fill': '拉伸填充',
  'wallpaper_fit_fit_height': '适配高度',
  'wallpaper_fit_fit_width': '适配宽度',
  'wallpaper_fit_mode': '填充模式',
  'wallpaper_fit_none': '原始大小',
  'wallpaper_fit_scale_down': '等比缩小',
  'wallpaper_library': '壁纸库',
  'wallpaper_library_entry_subtitle': '官方、Wallhaven、必应等图库',
  'wallpaper_library_loading': '壁纸库加载中…',
  'wallpaper_library_subtitle': '{count} 张 · {categories} 个分类',
  'wallpaper_mask': '遮罩',
  'wallpaper_next': '下一个',
  'wallpaper_pause': '暂停',
  'wallpaper_play': '播放',
  'wallpaper_prev': '上一个',
  'wallpaper_video_failed': '视频播放失败',
  'wallpaper_video_download_failed': '视频下载失败，已改用在线播放',
  'wallpaper_volume_down': '音量-',
  'wallpaper_volume_up': '音量+',
  'wallpaper_preview_hint': '←→ 选择按钮 · OK 确认 · 返回退出',
  'wallpaper_random_image': '随机图片',
  'wallpaper_set_background': '设为背景',
  'wallpaper_set_done': '已设为背景',
  'wallpaper_solid_color': '纯色',
  'wallpaper_solid_color_subtitle': '纯色与渐变填充',
  'wallpaper_source_group': '背景来源',
  'wallpaper_video_subtitle': '动态视频背景',
  'wallpaper_video_wallpaper': '视频壁纸',
  'unsupported_file_format': '不支持的文件格式',
  'provider_name_exists_tip': '该名称已存在，是否覆盖？',
  'subscription_download_or_parse_failed': '订阅下载或解析失败',

  // —— 站点名称 ——
  'site_all': '全部',
  'site_bilibili': '哔哩哔哩',
  'site_douyu': '斗鱼',
  'site_huya': '虎牙',
  'site_douyin': '抖音',
  'site_kuaishou': '快手',
  'site_cc': '网易CC',
  'site_twitch': 'Twitch',
  'site_soop': 'AfreecaTV(SOOP)',
  'site_yy': 'YY',
  'site_acfun': 'AcFun',
  'site_picarto': 'Picarto',
  'site_twitcasting': 'TwitCasting',
  'site_missevan': '猫耳FM',
  'site_openrec': 'OPENREC',
  'site_niconico': 'Niconico',
  'site_tting': 'TtingLive',
  'site_iptv': 'IPTV',

  // —— Niconico 目录 ——
  'niconico_category_common': '一般',
  'niconico_category_try': '尝试',
  'niconico_category_live': '实况',
  'niconico_category_req': '募集',
  'niconico_category_face': '表情',
  'niconico_category_totu': '凸待',
  'niconico_category_vtuber': 'VTuber',

  // —— HTTP 错误 ——
  'http_error_400': '请求错误(400)',
  'http_error_401': '未授权(401)',
  'http_error_403': '禁止访问(403)',
  'http_error_404': '未找到资源(404)',
  'http_error_500': '服务器错误(500)',
  'http_error_502': '网关错误(502)',
  'http_error_503': '服务不可用(503)',
  'http_error_default': '网络错误({statusCode})',
};

String i18n(String key, {Map<String, String>? args}) {
  var text = _translate(key);
  args?.forEach((name, value) {
    text = text.replaceAll('{$name}', value);
  });
  return text;
}

String i18nOr(String key, String fallback, {Map<String, String>? args}) {
  if (!i18nExists(key)) return fallback;
  return i18n(key, args: args);
}

bool i18nExists(String key) => _hasTranslation(key) || _labels.containsKey(key);

/// Lookup order: easy_localization assets first, then the built-in table.
/// The static table keeps offline and test callers working; a missing key is
String _translate(String key) {
  if (_hasTranslation(key)) return ez.tr(key);
  return _labels[key] ?? key;
}

bool _hasTranslation(String key) {
  try {
    return ez.trExists(key);
  } catch (_) {
    // EasyLocalization 尚未初始化时只依赖静态表。
    return false;
  }
}
