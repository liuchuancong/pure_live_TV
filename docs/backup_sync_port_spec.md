# Backup / Sync settings port spec — mobile (`D:\flutter\pure_live`) → TV (`pure_live_TV`)

Reference read at mobile v3.1.4+4103 (`D:\flutter\pure_live\pubspec.yaml:4`). The Firebase group is ignored throughout.

Paths below are prefixed `M:` for `D:\flutter\pure_live` and `T:` for `C:\Users\XA-158\projects\flutter\pure_live_TV`.
The TV app was being edited while this was written; TV findings are stated as of the timestamps noted in §5.

---

## 1. Mobile behaviour per row

All rows live on one page: `M:lib/modules/backup/backup_page.dart` (route `kBackupRecover`… registered as `backup_page.dart`, groups at :51 云端备份, :137 本地备份, :159 备份设置, :172 日志管理; Firebase row :53-112 skipped).

| Row (key) | Handler | What it opens / calls |
|---|---|---|
| `remote_sync` (:121-126) | `Get.toNamed(RoutePath.kRemoteSync)` | `RemoteSyncPage` + `RemoteSyncBinding` (`M:lib/routes/app_pages.dart:244-248`, path `M:lib/routes/route_path.dart:114`) |
| `sync_tv_data` (:127-134) | `Get.to(() => ScanCodePage())` | QR scanner; **guarded by `if (Platform.isAndroid \|\| Platform.isIOS)`** |
| `create_backup` (:139-149) | `BackupRecoveryService().createAppSettingsBackup(backupDirectory)` | local file export |
| `recover_backup` (:150-156) | `BackupRecoveryService().recoverSettingsFromFile()` | file picker → import |
| `backup_directory` (:161-169) | `BackupRecoveryService().updateBackupDirectory()` | directory picker → persisted |
| `enable_local_log` (:174-199) | `LogController.setLoggingEnabled(bool)` | log file sink + loopback log server |
| `view_logs_in_browser` (:200-223) | `launchUrl(uri, externalApplication)` | `http://<serverAddress>:<serverPort>` |
| `open_log_dir` (:225-231) | `_openLogDirectory()` (:26-39) | `FileUtils.openFileOrUrl(logDir.path)` |

### 1.1 `remote_sync` — 设备同步 (LAN device sync) — fully implemented, all platforms

Everything hangs off `RemoteSyncService` (`M:lib/modules/backup/remote_receiver/remote_sync_service.dart`), a GetX controller bound with `Bind.lazyPut` (`M:.../remote_sync_binding.dart:7`), so `Get.find` in the page's field initializer (`remote_sync_page.dart:19`) instantiates it and runs `onInit` (:116-121) → `start()` (:134) → `_refreshNetworkInfo` + `startServer` + `startDiscovery`.

**Transport — three parts, no WebSocket, no pairing, no auth:**

1. **Plain HTTP server.** `HttpServer.bind(InternetAddress.anyIPv4, port, shared: true)` starting at `39888`, incrementing up to 100 times on bind failure (:383-389). Port constant `RemoteSyncProtocol.defaultHttpPort = 39888` (`M:.../remote_sync_protocol.dart:2`). Response headers set CORS `*` and content-type `application/json; charset=utf-8` (:427-433); `OPTIONS` answered 200 (:435-439).
2. **mDNS/Bonsoir** (`bonsoir` package, `M:pubspec.yaml`), service type `_my-service._tcp` (:34), advertised name `PureLive-<last 6 of deviceId>` (:98-102) with TXT attributes `id,name,platform,version,ip` (:938-945). Discovery events add/update/remove a `RemoteSyncDevice` (:742-874), self-filtered by device id or by matching a local IP (:794-804). Devices not seen for 120 s are dropped every 15 s (:968-982).
3. **QR** encodes `purelive://<ip>:<port>/sync` (`createQrUri`, protocol :11-13); the page renders it with `QrImageView` (`remote_sync_page.dart:198-204`) — pair with the phone's camera, no handshake.

Device id: Hive key `remote_sync_device_id`, generated `"<os>-<microsecondsSinceEpoch>"` (`remote_sync_service.dart:123-132`).

**Routes (both ends implement the same two):**

| Constant | Path | Methods | Payload |
|---|---|---|---|
| `apiStatus` (protocol :8) | `/api/remote-sync/status` | GET | resp `{code:200,msg:'ok',data:{id,name,platform,version,ip,port}}` (`remote_sync_service.dart:483-494`) |
| `apiSettings` (protocol :9) | `/api/remote-sync/settings` | GET | resp `{code:200,msg:'ok',data:<exportAllSettings()>}` (:525-541) |
| `apiSettings` | `/api/remote-sync/settings` | POST | req `{type:'pure_live_sync', version:1, settings:{…}}`; resp `{code:200\|500,msg,data:bool}` (:549-631) |

`type` must equal `RemoteSyncProtocol.syncType = 'pure_live_sync'` (protocol :6; checked :581-591). Non-GET/POST → 405 (:645-649), unknown path → 404 `{code:404,msg:'Not Found',data:false}` (:451-454).

**Payload format** — the *full* backup document, not a flat one:
- Send: `backup.exportAllSettings(includeSensitiveData: true)` wrapped in `RemoteSyncProtocol.settingsPacket` (:1002, :1016, protocol :34-36) → `POST http://ip:port/api/remote-sync/settings`.
- Receive (page `_receiveFromDevice`, :39-77): confirmation dialog (`remote_sync_receive_confirm`) → `GET /api/remote-sync/settings` via `getRemoteSettings` (:1085-1132, no confirm on the wire) → `backup.importAllSettings(settings)` (:633-643, :79-87).
- Manual address entry accepts `ip[:port]` or a full URL (`parseHttpAddress`, protocol :38-68) → send (:1138-1146); a separate button parses then receives (:352-372).
- QR scan is **mobile-only**: `_scanQr` returns immediately when `PlatformUtils.isDesktop` (:109-111), and the scanner action icon is hidden on desktop (:156-157). Consequently desktop ↔ desktop sync is manual-address only, and desktop never scans.

`exportAllSettings` is the canonical document: `{backupVersion:3, sensitiveDataIncluded:true, app, theme, roomCard, font, player, danmaku, volume, favorite, history, iptv, proxy, windowSize, exit, startup, tags, refresh, page, webdav, cookie}` (`M:lib/common/services/settings/backup_controller.dart:36-68`).

**Sensitive data crosses unencrypted and unauthenticated.** `remote_sync_sensitive_data` = "包含 Cookie 和 WebDAV 配置" and `includeSensitiveData: true` is hard-coded in both directions (:529, :1002). `redactSensitiveData` exists (backup_controller.dart:71-77) but is never called by the sync path. There is no token, PIN, or session; possession of the IP:port is the only authorization.

### 1.2 `sync_tv_data` — 同步TV数据 — mobile-only, minimal "push to a TV" flow

- **Platform-gated**: the row only renders on Android/iOS (`backup_page.dart:127`), and the target is the TV's *web remote* + a separate `/api/setSettings` endpoint, not the `remote_sync` protocol.
- `ScanCodePage` (`M:lib/modules/backup/scan_page.dart`) is a `mobile_scanner` camera page. It rejects anything that is not a clean HTTP(S) origin — no userinfo, path (except `/`), query, fragment, or control chars (`normalizeScanSyncAddress`, :22-48) — then calls `BackupRecoveryService.pushSettingsToRemoteServer(address)` (:83-85, :284).
- Push implementation (`M:lib/plugins/backup_recovery_service.dart:68-79`):
  ```dart
  HttpClient.instance.postJson(
    '$httpAddress/api/setSettings',
    queryParameters: {"settings": jsonEncode(backup.exportToTVSettings())},
  )
  ```
  i.e. **`settings` is a query parameter holding a JSON string**, and the reply is parsed as `jsonDecode(response)['data']`.
- Payload is *flat and lossy*, not the backup envelope: `exportToTVSettings` = `{...danmaku, ...favorite, ...history, customIptvUserAgent, ...cookie}` (`backup_controller.dart:410-426`). No `backupVersion`, no sections.
- The TV side of this contract lives in a different repo/branch of the desktop app; nothing in this mobile tree serves `/api/setSettings`. The TV receiver does **not** implement it (see §5.3), so as written a TV that only speaks `/api/remote-sync/*` will not accept a `sync_tv_data` push.

### 1.3 `create_backup` / `recover_backup` — 本地备份

Service: `M:lib/plugins/backup_recovery_service.dart` (class `BackupRecoveryService`, no DI — constructed inline).

```dart
Future<String?> createAppSettingsBackup(String backupDirectory);  // :13
Future<void>  recoverSettingsFromFile();                          // :41
Future<String?> updateBackupDirectory();                          // :59
Future<bool>  pushSettingsToRemoteServer(String httpAddress);      // :68
```

- **Create** (:13-39): requests storage permission first (`FileUtils.requestStoragePermission`, :15-19), then **always asks the user for a directory** via `FilePicker.getDirectoryPath(initialDirectory: backupDirectory.isEmpty ? null : backupDirectory)` (:21-23) — the setting is only a starting hint, never the silent target. Cancel returns null.
- **File name** (:26-27): `purelive_<yyyy>-<MM>-<dd>T<HH>_<mm>_<ss>.txt` (e.g. `purelive_2026-09-16T10_53_37.txt`). Extension is **`.txt`**, not `.json`, and it is written next to the chosen directory — the path is *not* stored.
- **Format**: pretty-printed JSON, 2-space indent, of `exportAllSettings()` (sensitive data included) — `BackupController.backup(File)` at `backup_controller.dart:319-327` (`JsonEncoder.withIndent('  ')`, `writeAsStringSync`).
- **Side effect** (:31-33): on success, if `backupDirectory.v.isEmpty`, it is set to the chosen directory (first successful choice sticks; commented at `backup_page.dart:145-146`).
- **Restore** (:41-57): `FilePicker.pickFile(dialogTitle: i18n("select_recover_file"), type: FileType.custom, allowedExtensions: ['txt'])` — an explicit picker, no fixed path. Then `BackupController.recover(File)` (`backup_controller.dart:364-379`) = `readAsStringSync` → `jsonDecode` → must be `Map<String,dynamic>` → `restoreAllSettings` → `importAllSettings` (validate identity + section structure, then per-section `parseConfig`/`fromJson`, `:113-197`), batch-persisted through `HivePrefUtil.persistBatch` under a re-entrancy guard (`:329-362`).
- A second entry point `recoverAndDelete(File)` (:381-408) imports and then deletes the file *and its parent directory* — used by the migration path, not by this page.

### 1.4 `backup_directory` — 备份设置

- **Chosen**: `BackupRecoveryService.updateBackupDirectory` → `FilePicker.getDirectoryPath()` with no initial directory (`backup_recovery_service.dart:59-66`), then `backup.backupDirectory.v = selectedDirectory`.
- **Stored**: `BackupController.backupDirectory = hiveString('backupDirectory', '')` (`backup_controller.dart:34`) — a Hive preference keyed `backupDirectory`.
- **Read**: only in two places — the row subtitle (`backup_page.dart:23`, :164: shows the path, or `please_set_backup_directory` when empty) and as the `initialDirectory` hint for the next create (:22). It is **not** used to locate files for restore, and `BackupController` itself never reads it.

### 1.5 日志管理

`enable_local_log` (`backup_page.dart:174-199`) drives `LogController` (`M:lib/common/services/settings/log_controller.dart`), which delegates to `Log.setEnabled(bool)` (`M:lib/core/common/log.dart:80-120`):

- Turning it **on** does three things: opens a session log file, starts a **loopback-only** `HttpServer` on an OS-chosen port (`HttpServer.bind(InternetAddress.loopbackIPv4, 0)`, :96-100, bind address pinned at :37), and publishes that endpoint into `LogController.serverAddress/.serverPort` (:115-117). Failure at any step closes both and returns false, and the switch reverts (`log_controller.dart:75-93`).
- **Log directory**: `LogFileWriter.resolveLogDirectory()` (`log.dart:551-560`) — Android: `<Downloads>/LOGS/log` (`AppPathManager.logFilesDirectoryPath`, `app_path_manager.dart:395`, `dirLogs='LOGS'` :24); everywhere else `AppPathManager().logFilesDir` = `<appDir>/LOGS/log` (`app_path_manager.dart:365`). File name is `<yyyy-MM-dd_HH-mm-ss>.log` (:526-528).
- **`view_logs_in_browser`** (`backup_page.dart:200-223`): row is *hidden* unless logging is on, not applying, and `serverPort != 0` (:201-205). Subtitle is the live `http://<address>:<port>` (:206-210); tapping `launchUrl(uri, LaunchMode.externalApplication)` (:217-221). The server serves one HTML page at `/` and accepts `POST /clear` with header `X-PureLive-Log-Action: clear`; everything else 404/405/403 (`classifyBrowserRequest`, log.dart:47-61; page render :191-419; security headers incl. CSP `default-src 'none'` :21-29). Because it binds loopback, this URL is only reachable **on the same machine**.
- **`open_log_dir`** (`backup_page.dart:26-39`, :225-231): `resolveLogDirectory()` → if missing toast `log_dir_not_exist` → `FileUtils.openFileOrUrl(logDir.path)` (`M:lib/plugins/file_utils.dart:109`), toast `open_log_dir_failed` on failure.

**Desktop-only / platform notes (be precise):** none of the three log rows is compile-time gated. In practice `view_logs_in_browser` is meaningful on desktop only, since on Android/iOS it binds loopback and the log dir is under Downloads; `open_log_dir` depends on the OS file-manager launch behind `FileUtils.openFileOrUrl`. The genuinely platform-gated item in this page is `sync_tv_data` (Android/iOS only). `remote_sync` itself runs on all platforms; only its *QR scanning* is mobile-only (`remote_sync_page.dart:109-111`, :156-157).

---

## 2. Mobile i18n keys + Chinese strings (`M:assets/translations/zh.json`)

| Key | zh | Line |
|---|---|---|
| `cloud_backup` | 云端备份 | 1411 |
| `local_backup` | 本地备份 | 1412 |
| `backup_settings` | 备份设置 | 1413 |
| `log_manage` | 日志管理 | 1414 |
| `backup_recover` | 备份与恢复 | 28 |
| `backup_recover_subtitle` | 创建备份与恢复 | 29 |
| `backup_recover_desc` | 一键导出您的本地配置或从云端导入 | 967 |
| `remote_sync` | 设备同步 | 1843 |
| `remote_sync_subtitle` | 通过局域网在设备之间同步配置 | 1844 |
| `sync_tv_data` | 同步TV数据 | 621 |
| `sync_tv_data_subtitle` | 将数据远程同步到TV | 622 |
| `create_backup` | 创建备份 | 89 |
| `create_backup_subtitle` | 可用于恢复当前数据 | 91 |
| `create_backup_success` | 创建备份成功 | 97 |
| `create_backup_failed` | 创建备份失败 | 90 |
| `recover_backup` | 恢复备份 | 517 |
| `recover_backup_subtitle` | 从备份文件中恢复 | 519 |
| `recover_backup_success` | 恢复备份成功 | 520 |
| `recover_backup_failed` | 恢复备份失败 | 518 |
| `backup_directory` | 备份目录 | 27 |
| `please_set_backup_directory` | 请先设置备份目录 | 92 |
| `enable_local_log` | 启用本地日志 | 1415 |
| `enable_local_log_desc` | 开启后将日志写入本地文件 | 1416 |
| `local_log_applying` | 正在更新本地日志状态… | 1417 |
| `local_log_apply_failed` | 本地日志状态未发生变化，开关已恢复为当前运行状态。 | 1418 |
| `view_logs_in_browser` | 在浏览器中查看日志 | 1440 |
| `open_log_dir` | 打开日志目录 | 1419 |
| `open_log_dir_desc` | 查看并管理日志文件 | 1420 |
| `log_dir_not_exist` | 日志目录不存在 | 1421 |
| `open_log_dir_failed` | 打开日志目录失败 | 1422 |

Remote-sync page keys (`remote_sync_page.dart`, `RemoteSyncService`), all present in `zh.json`:

| Key | zh | Line |
|---|---|---|
| `remote_sync_title` | 局域网设备同步 | 1845 |
| `remote_sync_description` | 请确保两台设备连接到同一个局域网 | 1846 |
| `remote_sync_my_device` | 我的设备 | 1847 |
| `remote_sync_scan_qr` | 扫描二维码 | 1848 |
| `remote_sync_manual` | 手动输入 | 1849 |
| `remote_sync_devices` | 发现的设备 | 1850 |
| `remote_sync_no_devices` | 未发现其他设备 | 1851 |
| `remote_sync_searching` | 正在搜索局域网设备... | 1852 |
| `remote_sync_refresh` | 重新搜索 | 1853 |
| `remote_sync_send` | 发送配置 | 1854 |
| `remote_sync_receive` | 接收配置 | 1855 |
| `remote_sync_ip_address` | IP 地址 | 1856 |
| `remote_sync_port` | 端口 | 1857 |
| `remote_sync_address` | 设备地址 | 1858 |
| `remote_sync_input_address` | 输入设备地址 | 1859 |
| `remote_sync_input_address_hint` | 例如：192.168.1.100:8888 | 1860 |
| `remote_sync_syncing` | 正在同步... | 1861 |
| `remote_sync_send_success` | 配置发送成功 | 1862 |
| `remote_sync_send_failed` | 配置发送失败 | 1863 |
| `remote_sync_receive_success` | 配置接收成功 | 1864 |
| `remote_sync_receive_failed` | 配置接收失败 | 1865 |
| `remote_sync_qr_expired` | 二维码已失效 | 1866 |
| `remote_sync_invalid_address` | 设备地址无效 | 1867 |
| `remote_sync_invalid_qr` | **MISSING from both `zh.json` and `en.json`** | — |
| `remote_sync_enter_address` | **MISSING from both `zh.json` and `en.json`** | — |
| `remote_sync_not_lan` | 当前网络不是局域网，无法进行设备同步 | 1868 |
| `remote_sync_no_network` | 当前没有可用的局域网连接 | 1869 |
| `remote_sync_device_unreachable` | 无法连接到目标设备 | 1870 |
| `remote_sync_confirm_send` | 确定要将当前设备的全部配置发送到此设备吗？ | 1871 |
| `remote_sync_confirm_receive` | 确定要使用此设备的配置覆盖当前设备吗？ | 1872 |
| `remote_sync_all_settings` | 全部配置 | 1873 |
| `remote_sync_sensitive_data` | 包含 Cookie 和 WebDAV 配置 | 1874 |
| `remote_sync_scan_hint` | 使用另一台设备扫描此二维码 | 1875 |
| `remote_sync_manual_sync` | 输入 IP 和端口进行同步 | 1876 |
| `remote_sync_device_info` | 设备信息 | 1877 |
| `remote_sync_platform` | 平台 | 1878 |
| `remote_sync_version` | 版本 | 1879 |
| `remote_sync_copy_address` | 复制地址 | 1880 |
| `remote_sync_address_copied` | 地址已复制 | 1881 |
| `remote_sync_cancel` | 取消 | 1882 |
| `remote_sync_confirm` | 确认 | 1883 |
| `remote_sync_no_address` | 未获取到本机地址 | 1884 |
| `remote_sync_not_running` | 同步服务未运行 | 1885 |
| `remote_sync_running` | 同步服务运行中 | 1886 |
| `remote_sync_receive_confirm` | 是否接收远程同步的配置？ | 1887 |
| `remote_sync_select_action` | 选择同步操作 | 1888 |
| `backup_to_webdav` | 备份到WebDav服务器 | 30 |

Note the 同步TV数据 flow uses different keys (`M:assets/translations/zh.json`): `scan_qr_code` 扫描二维码 (:542), `scanner_sync_hint` 扫描电视端显示的服务器二维码 (:545), `scanner_camera_error` :543, `scanner_switch_camera` :544, `scanner_toggle_torch` :546, `syncing` 正在同步 (:623), `sync_success` 同步成功 (:620), `sync_failed` 同步失败 (:619), `retry` 重试 (:536), `select_recover_file` 选择备份文件 (:560), `grant_storage_permission_first` 请先授予读写文件权限 (:312).

**Two upstream i18n bugs worth not copying:** `remote_sync_page.dart:93` and `:122` call `i18n('remote_sync_enter_address')` and `i18n('remote_sync_invalid_qr')`, neither of which exists in `M:assets/translations/zh.json` or `en.json` — mobile ships raw key text in those two toasts. Any TV port should use existing keys instead.

---

## 3. TV app current state (gap)

| Mobile row | TV status |
|---|---|
| `cloud_backup` group | present (`T:lib/features/settings/pages/backup_settings_section.dart:100`) |
| `remote_sync` | **row + page present** (`backup_settings_section.dart:109-114` → `device_sync_section.dart`) but the route constant `AppRoutes.kSettingsDeviceSync` is **not declared** in `T:lib/app/router/app_routes.dart` (last const `kSettingsLocalBackup` :142) nor registered in `T:lib/app/router/app_router.dart` — currently a compile error |
| `sync_tv_data` | **absent** — no row, no page, no `/api/setSettings` route; also meaningless on a TV (no camera) |
| `create_backup` | present (`backup_settings_section.dart:122-129`, `backup_manage_section.dart:125-132`); writes `pure_live_backup_<yyyyMMdd_HHmmss>.json` into `resolveBackupDirectory()` |
| `recover_backup` | present as a **list page** (`backup_manage_section.dart`), not a file picker; restores from the 20 most recent `pure_live_backup*.json` |
| `backup_directory` | present (`backup_settings_section.dart:143-150`) via `FilePicker.platform.getDirectoryPath()` → `setBackupDirectory` |
| `enable_local_log` | present (`backup_settings_section.dart:158-166`) |
| `view_logs_in_browser` | present but **re-pointed**: shows `<serverUrl>/api/log/download` (`backup_settings_section.dart:68-83`) rather than a loopback URL |
| `open_log_dir` | **absent** from the settings page (helper exists: `T:lib/shared/platform/file_utils.dart:111 openFileOrUrl`) |

Every key the current TV rows use already exists in `T:assets/translations/zh.json`: `cloud_backup` :1411, `local_backup` :1412, `backup_settings` :1413, `log_manage` :1414, `remote_sync` :1843, `remote_sync_subtitle` :1844, `create_backup`/`create_backup_subtitle`/`recover_backup`/`recover_backup_subtitle`/`backup_directory`/`please_set_backup_directory`/`enable_local_log`/`enable_local_log_desc`/`view_logs_in_browser`/`open_log_dir_desc`, plus TV-only helpers `remote_service_unavailable` :88, `ui_running` :1915, `ui_stopped` :1916, `ui_choose` :1917, `ui_show` :1918, `ui_loading` :1997. So the port needs **no new translation entries** for the rows that exist; only a future `open_log_dir` row reuses `open_log_dir`/`log_dir_not_exist`/`open_log_dir_failed`, which are also already present.

### 3.1 Existing TV equivalents (already close to mobile)

- `T:lib/services/backup/backup_controller.dart` mirrors mobile almost 1:1: `backupVersion = 3` (:12), `backupDirectoryKey = 'backupDirectory'` (:13), `backupDirectory` getter/setter over `HivePrefUtil` (:40-44), `exportAllSettings` (:46-74, sections `app/theme/font/player/danmaku/volume/favorite/history/webdav/iptv/cookie/proxy/exit/startup/refresh/page/log/tags`), `validateSectionStructure` (:90), `validateBackupIdentity` (:100), `backup(File)` (:170-178), `restoreAllSettings` (:181-189), `recover(File)` (:191-201), `recoverAndDelete` (:204-228), `exportToTVSettings` (:231-244). It adds `knownSections` with `log` but **not** `roomCard`/`windowSize`, and `resolveBackupDirectory()` (:52-…) falls back to `getApplicationDocumentsDirectory()`.
- Consequence: **TV and mobile backup documents are cross-loadable** in both directions except that mobile's `roomCard`/`windowSize` sections are ignored by the TV importer and TV's `log` section is ignored by mobile. `backupVersion` matches at 3.
- `T:lib/services/settings/backup_recovery_service.dart` is a near-copy of the mobile service (same class name and method set, :18/:31/:37/:44) including the legacy `pushSettingsToRemoteServer` → `POST $addr/api/setSettings?settings=…` (:44-54) — but it is **not referenced by any UI** (only self-reference found). It is effectively dormant code.

### 3.2 `T:lib/features/remote/tv_remote_receiver.dart` — the LAN server the TV already runs

Riverpod `@riverpod class TvRemoteReceiver` (`:15-16`), autoDispose, state `ServerState{isRunning,serverUrl,port,error}` (`:8-11`), default port **8888** with the same +1 retry loop (`:40`, `:124-126`), bound `0.0.0.0` (`:118`), built on `alfred` (`T:pubspec.yaml:114`) with global CORS (`:158-168`).

Routes registered at `:195-360`:

| Method + path | Behaviour |
|---|---|
| `GET /ws` | WebSocket upgrade; sends `{type:'init',device,version,timestamp}` (:170-193) |
| `GET /api/status` | `{device,version}` (:196-199) |
| `GET /api/version` | `{version}` (:201) |
| `POST /api/movie` | body = raw URL, callback + WS broadcast (:203-211) |
| `POST /api/search/streamer`, `POST /api/search/room` | raw body (:213-227) |
| `GET/POST /api/cookie`, `GET/POST /api/cookie/douyin` | per-site cookie read/write (:229-261) |
| `GET/POST /api/danmaku_filter` | filter cache (:263-279) |
| `GET /api/remote-sync/status` | `{type:'pure_live_sync',version:1,platform,appVersion}` (:283-293) |
| `GET /api/remote-sync/settings` | `exportAllSettings()` of the TV (:295-297) |
| `POST /api/remote-sync/settings` | `settings = body['settings'] ?? body` → `restoreAllSettings` (:299-311) |
| `GET/POST /api/webdav/list`, `/api/webdav/save` | cache (:313-322) |
| `GET /api/backup/export` | `{version,export_time,config:_configCache}` + `Content-Disposition` attachment (:324-331) |
| `POST /api/backup/import` | merges `body['config']` into `_configCache` (:333-341) |
| `GET /api/log/stream`, `GET /api/log/download`, `POST /api/log/clear` | in-memory log buffer (:343-359) |
| `GET *` | static `assets/web_remote/**`, else `index.html` SPA fallback (:362-388) |

Response envelope helpers: `_ok` → HTTP 200 `{code:200,msg,data}` (`:421-424`); `_fail` → HTTP 400 `{code:400,msg,data:null}` (`:426-430`). Mobile's client only inspects `data` (`backup_recovery_service.dart:75`) and HTTP 200 (`remote_sync_service.dart:1022`), so the envelopes are compatible.

**How a phone talks to it today:** the bundled web remote (`T:assets/web_remote/assets/`, Vue SPA) — `api-*.js` calls `/api/version|movie|search/*|cookie*|danmaku_filter|webdav/*|backup/export|backup/import|log/*`. Note `/api/backup/*` uses a **third, flat and lossy** payload (`{version, export_time, config:{douyin_cookie, danmaku_filter, webdav_list}}`, `_configCache` at `:23-27`) and is *not* a full settings backup. Its `SyncRemote-*.js` page does **not** call `/api/remote-sync/*` (verified: none of the three bundles, nor any api bundle, contain the string `remote-sync`), so the good protocol is currently reachable only by the native mobile app, not by the TV's own web remote UI.

### 3.3 LAN/remote/sync grep results under `T:lib`

- `remote-sync` / `sync_tv_data` / `setSettings`: `tv_remote_receiver.dart:283,295,299`, `services/settings/backup_recovery_service.dart:47`. No `sync_tv_data` row or page anywhere.
- `HttpServer`: only `tv_remote_receiver.dart:18`.
- `bonsoir`/`mdns`: **no code**, but the dependency is already declared (`T:pubspec.yaml:122 bonsoir: ^7.1.5 # 局域网同步`). No mDNS advertising or discovery on the TV.
- No dedicated `lan`/`device_sync` service exists; the only LAN server is the remote receiver, consumed by `account_settings_section.dart:274`, `tv_search_page.dart:32`, `tv_search_result_page.dart:29`, `shield_panel.dart:37`, `movie_playback_page.dart:25`.

---

## 4. `remote_sync` / `sync_tv_data` — recommendation

### 4.1 `remote_sync`: reuse `tv_remote_receiver.dart` — cheap ✅

The TV already implements the mobile `remote_sync` protocol **byte-for-byte on the wire**. Verified pairs:

| Mobile expectation | TV implementation | Compatible? |
|---|---|---|
| GET `/api/remote-sync/status` (`remote_sync_protocol.dart:8`) | `tv_remote_receiver.dart:283` | ✅ (TV adds no `id`/`name`/`ip`/`port` fields, but the mobile manual/QR paths never read them; only the discovery list does) |
| GET `/api/remote-sync/settings` → `{code:200,msg,data}` (`remote_sync_service.dart:1105-1125`) | `tv_remote_receiver.dart:295` via `_ok` | ✅ |
| POST `/api/remote-sync/settings` with `{type:'pure_live_sync',version:1,settings:{…}}` (`remote_sync_service.dart:1016`, protocol :34-36) | `tv_remote_receiver.dart:299-304` reads `body['settings']` (tolerates a bare map too) | ✅ returns `{code:200,msg,data:true}` |
| `includeSensitiveData: true` | TV export/import both include cookie+webdav | ✅ compatible superset |

So a phone running the mobile app can already sync with this TV **right now** by entering the TV address manually in 设备同步 (`remote_sync_page.dart:321-372`) — the TV's `serverUrl` is shown on the new device-sync page.

What to add, cheapest first:

1. **Fix the missing route** (minutes). Declare `static const kSettingsDeviceSync = "/settings/device_sync";` in `app_routes.dart` and register `GoRoute(path: …)` in `app_router.dart` next to `backups` (`app_router.dart:86`). Until then the app does not compile.
2. **Populate `GET /api/remote-sync/status` with device identity** (minutes). Add `id`, `name`, `ip`, `port` alongside `type`/`version` so a phone/desktop doing discovery renders 我的设备/设备信息 correctly and so `_isSelfService`-style filtering works. Keep `type:'pure_live_sync'` — mobile's status handler does not check it, but the `POST` handler does check `type`, and keeping the field avoids a future client rejecting the response.
3. **mDNS advertisement** (an hour). Call `BonsoirBroadcast` with `type: '_my-service._tcp'` and TXT `{id,name,platform,version,ip}` from `TvRemoteReceiver.startServer`, mirroring `remote_sync_service.dart:916-962`, and stop it in `stopServer` (`:450`). `bonsoir` is already a dependency. Without this, the mobile app's 发现的设备 list (auto-discovery) will never show the TV and users must type/scan the address. Two cautions: do not reuse mobile's `RemoteSyncProtocol.defaultHttpPort` (39888) as the TV's port — the TV service is 8888, so advertise the *actual* bound port (`server.state.port`, `server_state.dart:8-9`); and mobile prefers a resolved IP in the same `/24` (`remote_sync_service.dart:876-910`), which works fine here.
4. **QR payload** (mostly free). `device_sync_section.dart:86` already renders `TvQrCodeCard(qrData: url)` with `url = serverUrl` = `http://<ip>:8888`. Mobile's `sync_tv_data` scanner accepts that (bare HTTP origin, `scan_page.dart:22-48`), and mobile's *device-sync* scanner additionally accepts `purelive://<ip>:<port>/sync` (`remote_sync_protocol.dart:70-92`). Prefer encoding the **`purelive://` URI** so the receiving app knows this is a sync peer and can offer send/receive (`remote_sync_page.dart:126-147`); the plain `http://ip:8888` form remains a valid fallback. No pairing token is involved in either case.

Cost: **low.** Expected work is a route constant + route registration, a richer status body, and optional mDNS/QR polish. No new transport, no new protocol, no new dependency, no security model beyond what mobile already ships (unauthenticated LAN with CORS `*`).

### 4.2 `sync_tv_data`: a port, but a deliberately narrow one — medium ⚠️

This is **not** the same protocol. Mobile posts the *flat* `exportToTVSettings()` document as a **query parameter** to `/api/setSettings` (`plugins/backup_recovery_service.dart:68-79`) and expects `{"data": true}`. The TV has no such route, so today that push lands on the static catch-all (`tv_remote_receiver.dart:363`) and returns HTML — the mobile app would silently report failure.

Cheap way to make it work:

- Add `POST /api/setSettings` to `_registerApiRoutes`: read `req.uri.queryParameters['settings']`, `jsonDecode` it, and apply it. Since the flat document has no `backupVersion` or sections, `BackupController.validateBackupIdentity` will accept it only via the legacy branch — mobile's own `importAllSettings` handles exactly this shape through `_importLegacy` (`backup_controller.dart:290-317`). The TV's `importAllSettings` should be checked for the same legacy tolerance before promising this. Reply `{code:200,msg:'ok',data:true}` (mobile reads `['data']`).
- Fields actually carried: danmaku + favorite + history + `customIptvUserAgent` + cookie. Nothing else. So it is a *partial* sync by design — a TV receiving it will not get theme/player/app settings.

Expensive / not worth it: replicating the *sending* half on the TV. `sync_tv_data` is `mobile_scanner`-based and Android/iOS-gated (`backup_page.dart:127`); a TV has no camera, so the row has no meaning on the target platform. Recommendation: **omit the `sync_tv_data` row on the TV** and instead make the TV's 设备同步 page the single sync surface; if mobile-compat matters, implement the receiving `POST /api/setSettings` shim only (a handful of lines), and note that the flat payload is lossy compared with the good protocol.

### 4.3 Cheap vs expensive summary

| Item | Cost | Note |
|---|---|---|
| `kSettingsDeviceSync` route constant + registration | **cheap** | currently a compile error (`backup_settings_section.dart:113`) |
| `remote_sync` full send/receive with mobile app | **cheap** | already implemented in `tv_remote_receiver.dart:283-311` |
| Richer `/api/remote-sync/status` body | **cheap** | parity with `remote_sync_service.dart:483-494` |
| mDNS `_my-service._tcp` advertise | **cheap** | `bonsoir` already in `pubspec.yaml:122`; advertise the real 8888 port |
| `purelive://` QR instead of bare URL | **cheap** | `device_sync_section.dart:86` already has the widget |
| `POST /api/setSettings` legacy shim for `sync_tv_data` | **cheap-ish** | verify TV `importAllSettings` accepts the flat/legacy shape first |
| `sync_tv_data` *sender* on TV | **not applicable** | camera-based, Android/iOS-only upstream |
| Web-remote 设备同步 UI (buttons over `/api/remote-sync/*`) | **medium** | the existing `SyncRemote` page speaks only `/api/backup/*` (flat `_configCache`), which is lossy; a rebuild is needed to reach the good protocol |
| Transport-level auth / pairing for LAN sync | **expensive, out of scope** | upstream has none; a TV port should not invent it silently, but note that `0.0.0.0` + CORS `*` exposes full settings *including cookies and WebDAV credentials* to anyone on the LAN |

### 4.4 Other TV gaps worth closing for parity

- **`create_backup` naming/format**: TV writes `.json` (`backup_settings_section.dart:49`, `backup_manage_section.dart`), mobile writes `.txt` (`plugins/backup_recovery_service.dart:27`). Keep `.json` on TV (better) but be aware mobile's restore filters `allowedExtensions: ['txt']` (`:46`), so a TV-produced file cannot be selected by the mobile restore picker. If cross-device restore matters, write `.txt` or offer both.
- **`recover_backup`**: mobile is a file picker; TV is an in-app list of 20 recent backups (`backup_manage_section.dart:21`, `:136-169`). Functional, but there is no way to import a backup the user copied onto the TV. Adding a `FilePicker.pickFile` path (dependency already present, `pubspec.yaml:55`) would close it.
- **`view_logs_in_browser`**: TV shows `<serverUrl>/api/log/download` (`backup_settings_section.dart:81`) — a plain-text download over the LAN remote, not the mobile's loopback HTML console with auto-refresh/clear (`M:lib/core/common/log.dart:191-419`). This is a reasonable TV adaptation (a TV has no browser) but it is a different feature: no live view, no clear button from the browser.
- **`open_log_dir`**: implement as `FileUtils.openFileOrUrl((await AppPathManager().logsDir).path)` (`T:lib/shared/utils/log.dart:252`, `T:lib/shared/platform/file_utils.dart:111`), with `log_dir_not_exist`/`open_log_dir_failed` toasts. Cheap.
- **`enable_local_log` error reporting**: the earlier revision showed `local_log_apply_failed` on failure; the current one (`backup_settings_section.dart:163-165`) discards the boolean returned by `setLoggingEnabled` (`T:lib/services/log_settings/log_settings_controller.dart:25-31`), so a failed enable silently flips back. Restore the mobile behaviour (`M:lib/common/services/settings/log_controller.dart:88-100`) — cheap, and the i18n keys already exist.
- **Sensitive-data export**: both apps export cookies/WebDAV unconditionally in `create_backup` (`backup_controller.dart:69-72`). No change needed, but the LAN remote makes the TV copy network-reachable, which is worth a one-line warning in the UI.
