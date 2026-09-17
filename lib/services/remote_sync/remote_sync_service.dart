import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';
import 'package:pure_live/features/remote/index.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_model.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/tag_management/tag_management_controller.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/common/http_header_policy.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tv_remote_kit/tv_remote_kit.dart';

part 'remote_sync_service.g.dart';

/// What the UI needs to know about the LAN sync service: the QR payload, the
/// manually typeable address, and the peers currently discovered.
class RemoteSyncSnapshot {
  final bool started;
  final String qrData;
  final String address;

  /// `http://ip:port/` — the page the phone opens.
  final String webAddress;
  final String? error;
  final List<RemoteSyncDevice> devices;

  const RemoteSyncSnapshot({
    this.started = false,
    this.qrData = '',
    this.address = '',
    this.webAddress = '',
    this.error,
    this.devices = const [],
  });
}

/// Bridges the storage-free [TvRemoteKit] to the app's controllers.
///
/// Channel reads/writes land on the real services (cookies, danmaku shield
/// words, tags, proxy, IPTV, full settings), and phone pushes are forwarded
/// into the same [TvRemoteReceiver] callbacks the web remote already drives —
/// so every page that listens for phone input needs no change at all.
@Riverpod(keepAlive: true)
class RemoteSyncController extends _$RemoteSyncController {
  TvRemoteKit? _kit;
  StreamSubscription<RemoteSyncEvent>? _eventSubscription;

  TvRemoteKit? get kit => _kit;

  @override
  RemoteSyncSnapshot build() {
    ref.onDispose(() {
      _eventSubscription?.cancel();
      unawaited(_kit?.stop());
      _kit = null;
    });

    unawaited(_boot());
    return const RemoteSyncSnapshot();
  }

  /// Starts a kit and publishes the outcome — including a failure.
  ///
  /// The publish used to happen only on the success path, so a start that failed (or that
  /// found no LAN address) left the card on "正在启动局域网同步服务器" with nothing to do.
  Future<void> _boot() async {
    final kit = TvRemoteKit(
      deviceId: _loadDeviceId(),
      deviceName: 'PureLive TV (${Platform.operatingSystem})',
      delegate: _AppSyncDelegate(ref),
    );
    _kit = kit;
    _eventSubscription = kit.events.listen(_handleEvent);
    await kit.start();
    _publish(kit);
  }

  /// Restarts the service after a failure. The kit cannot be restarted once stopped, so
  /// this builds a fresh one.
  Future<void> restart() async {
    final TvRemoteKit? old = _kit;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _kit = null;
    if (ref.mounted) state = const RemoteSyncSnapshot();
    await old?.stop();
    await _boot();
  }

  void _handleEvent(RemoteSyncEvent event) {
    switch (event) {
      case RemoteDevicesChangedEvent():
        _publish(_kit);
      case RemoteTextInputEvent(:final kind, :final text):
        // Converge both transports on the callbacks the pages already bind:
        // web-remote pushes and kit pushes reach the same place.
        final receiver = ref.read(tvRemoteReceiverProvider.notifier);
        switch (kind) {
          case 'streamer':
            receiver.onStreamerSearch?.call(text);
          case 'room':
            receiver.onRoomPush?.call(text);
          case 'movie':
            receiver.onMovieReceived?.call(text);
        }
      case RemoteChannelEvent(:final channel):
        if (channel == 'danmaku_filter') {
          final filters = ref.read(favoriteRoomControllerProvider).shieldList;
          ref.read(tvRemoteReceiverProvider.notifier).onDanmakuFilterUpdated?.call(filters);
        }
      case RemoteLogEvent():
        break;
    }
  }

  void _publish(TvRemoteKit? kit) {
    if (!ref.mounted || kit == null) return;
    state = RemoteSyncSnapshot(
      started: kit.isRunning,
      qrData: kit.qrData,
      address: kit.address,
      webAddress: kit.webAddress,
      error: kit.isRunning ? null : _startFailure(kit.lastError),
      devices: kit.devices,
    );
  }

  /// The message the card shows instead of an endless spinner.
  String? _startFailure(String? reason) =>
      reason == null ? null : '${i18n('remote_sync_start_failed')}（$reason）';

  static String _loadDeviceId() {
    const key = 'remote_sync_device_id';
    final existing = HivePrefUtil.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 'tv-${DateTime.now().microsecondsSinceEpoch}';
    HivePrefUtil.setString(key, id);
    return id;
  }
}

/// The app half of the delegate: every channel lands on its controller.
class _AppSyncDelegate extends RemoteSyncDelegate {
  const _AppSyncDelegate(this._ref);

  final Ref _ref;

  @override
  Future<Object?> channelState(String channel) async {
    switch (channel) {
      case 'cookie':
        return _cookiesBySite();
      case 'danmaku_filter':
        return _ref.read(favoriteRoomControllerProvider).shieldList;
      case 'tags':
        return [
          for (final tag in _ref.read(tagManagementControllerProvider).tags)
            {'name': tag.name, 'description': tag.description},
        ];
      case 'proxy':
        return _ref.read(proxySettingsControllerProvider).toJson();
      case 'iptv':
        return _ref.read(iptvSettingsControllerProvider).toJson();
      default:
        return null;
    }
  }

  @override
  Future<bool> applyChannel(String channel, Object? data) async {
    switch (channel) {
      case 'cookie':
        if (data is! Map) return false;
        final site = (data['site'] ?? '').toString().trim().toLowerCase();
        final value = (data['data'] ?? '').toString();
        return _setCookieForSite(site, value);
      case 'danmaku_filter':
        return _replaceShieldList(_stringListFrom(data));
      case 'tags':
        return _applyTags(data);
      case 'proxy':
        if (data is! Map) return false;
        try {
          _ref
              .read(proxySettingsControllerProvider.notifier)
              .updateSettings(ProxySettingsModel.fromJson(Map<String, dynamic>.from(data)));
          return true;
        } catch (_) {
          return false;
        }
      case 'iptv':
        return _applyIptvLink(data);
      default:
        return false;
    }
  }

  @override
  Future<Map<String, dynamic>> exportSettings() async {
    return _ref.read(backupControllerProvider.notifier).exportAllSettings();
  }

  @override
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    final backup = _ref.read(backupControllerProvider.notifier);
    try {
      await backup.restoreAllSettings(settings);
      return true;
    } catch (_) {
      // The phone's 同步TV数据 row posts a flat document rather than a
      // sectioned backup; hand every section the whole map so each parser
      // picks its own keys out of it.
      try {
        await backup.restoreAllSettings(<String, dynamic>{
          'backupVersion': 1,
          'danmaku': settings,
          'favorite': settings,
          'history': settings,
          'cookie': settings,
          'iptv': settings,
        });
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  // -- cookie ------------------------------------------------------------

  Map<String, String> _cookiesBySite() {
    final cookies = SettingsService.to.cookieState;
    return {
      'bilibili': cookies.bilibiliCookie,
      'huya': cookies.huyaCookie,
      'douyin': cookies.douyinCookie,
      'kuaishou': cookies.kuaishouCookie,
      'yy': cookies.yyCookie,
      'soop': cookies.soopCookie,
      'twitch': cookies.twitchCookie,
    };
  }

  bool _setCookieForSite(String site, String cookie) {
    final controller = SettingsService.to.cookieManager;
    switch (site) {
      case 'bilibili':
        controller.setBilibiliCookie(cookie);
      case 'huya':
        controller.setHuyaCookie(cookie);
      case 'douyin':
        controller.setDouyinCookie(cookie);
      case 'kuaishou':
        controller.setKuaishouCookie(cookie);
      case 'yy':
        controller.setYyCookie(cookie);
      case 'soop':
        controller.setSoopCookie(cookie);
      case 'twitch':
        controller.setTwitchCookie(cookie);
      default:
        return false;
    }
    return true;
  }

  // -- danmaku shield words ---------------------------------------------

  List<String> _stringListFrom(Object? data) {
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is Map && data['filters'] is List) {
      return (data['filters'] as List).map((e) => e.toString()).toList();
    }
    if (data is String) {
      return data.split('\n').where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }

  Future<bool> _replaceShieldList(List<String> filters) async {
    final fav = SettingsService.to.fav;
    final current = List<String>.from(_ref.read(favoriteRoomControllerProvider).shieldList);
    for (var i = current.length - 1; i >= 0; i--) {
      fav.removeShieldList(i);
    }
    var ok = true;
    for (final word in filters) {
      ok = fav.addShieldList(word) && ok;
    }
    return ok;
  }

  // -- tags --------------------------------------------------------------

  bool _applyTags(Object? data) {
    List? entries;
    if (data is List) {
      entries = data;
    } else if (data is Map && data['tags'] is List) {
      entries = data['tags'] as List;
    }
    if (entries == null) return false;

    final controller = SettingsService.to.tag;
    final existing = _ref
        .read(tagManagementControllerProvider)
        .tags
        .map((tag) => tag.name.trim().toLowerCase())
        .toSet();
    var added = false;
    for (final entry in entries) {
      final name = entry is Map ? (entry['name'] ?? '').toString().trim() : '';
      if (name.isEmpty) continue;
      if (existing.contains(name.toLowerCase())) continue;
      final description = entry is Map ? (entry['description'] ?? '').toString() : '';
      controller.addTag(name, description);
      existing.add(name.toLowerCase());
      added = true;
    }
    return added || entries.isEmpty;
  }

  // -- iptv link ---------------------------------------------------------

  Future<bool> _applyIptvLink(Object? data) async {
    String url;
    String name;
    Map<String, String> headers = const <String, String>{};
    if (data is Map) {
      url = (data['url'] ?? data['link'] ?? '').toString().trim();
      name = (data['name'] ?? '').toString().trim();
      final rawHeaders = data['headers'] ?? data['httpHeaders'];
      if (rawHeaders is Map) headers = HttpHeaderPolicy.normalize(rawHeaders);
    } else {
      url = data.toString().trim();
      name = '';
    }
    if (url.isEmpty || !url.startsWith('http')) return false;

    try {
      final content = await HttpClient.instance.getText(
        url,
        header: <String, String>{'user-agent': HttpClient.iptvUserAgent, ...headers},
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}iptv_remote_${DateTime.now().millisecondsSinceEpoch}.m3u');
      // The headers the user typed on the phone belong to the *channels* of this source,
      // not just to the download: `mergeIntoM3u` writes them into the playlist the parser
      // reads, which is how a playlist encodes its own UA/Referer/Cookie.
      await file.writeAsString(HttpHeaderPolicy.mergeIntoM3u(content, headers));
      final providerName = name.isNotEmpty ? name : 'remote_${DateTime.now().millisecondsSinceEpoch}';
      final ok = await IptvImportManager().importIptvFile(
        file: file,
        providerName: providerName,
        url: url,
        forceUpdate: true,
        showTips: false,
      );
      await file.delete();
      return ok;
    } catch (_) {
      return false;
    }
  }
}