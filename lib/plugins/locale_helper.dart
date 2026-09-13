/// 同步自 pure_live 的 i18n 能力。
/// TV 端未引入 easy_localization，这里以静态键值表提供站点适配层用到的
/// 平台提示文案；i18nOr 在缺少键时返回 fallback，保持调用点兼容。
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
};

String i18n(String key, {Map<String, String>? args}) {
  var text = _labels[key] ?? key;
  args?.forEach((name, value) {
    text = text.replaceAll('{$name}', value);
  });
  return text;
}

String i18nOr(String key, String fallback, {Map<String, String>? args}) {
  if (!_labels.containsKey(key)) return fallback;
  return i18n(key, args: args);
}

bool i18nExists(String key) => _labels.containsKey(key);
