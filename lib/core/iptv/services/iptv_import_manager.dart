import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/file_utils.dart';
import 'package:pure_live/plugins/db_service.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:pure_live/core/iptv/parsers/m3u_parser.dart';
import 'package:pure_live/core/iptv/parsers/txt_parser.dart';
import 'package:pure_live/common/utils/app_path_manager.dart';
import 'package:pure_live/core/iptv/local/database.dart' as database;

class IptvImportManager {
  Future<bool> importFromNetworkUrl(
    String url,
    String fileName, {
    bool forceUpdate = false,
    bool showTips = true,
    bool isHot = false,
  }) async {
    final dir = await AppPathManager().getDir(AppPathManager.dirIptvCache);
    final file = File(p.join(dir.path, 'download_iptv_${FileUtils.generateUuid()}.m3u'));

    try {
      String cleanName = p.basename(fileName);
      while (p.extension(cleanName).isNotEmpty) {
        cleanName = p.basenameWithoutExtension(cleanName);
      }
      fileName = cleanName;

      final lowercaseUrl = url.toLowerCase().trim();
      if (!{'.m3u', '.txt', '.m3u8'}.any((ext) => lowercaseUrl.endsWith(ext))) {
        if (showTips) {
          ToastUtil.show("不支持的文件格式，仅限 M3U 或 TXT");
        }
        return false;
      }

      final String rawStringContent = await HttpClient.instance.getText(url);
      if (rawStringContent.trim().isEmpty) {
        if (showTips) {
          ToastUtil.show("不支持的文件格式，仅限 M3U 或 TXT");
        }
        return false;
      }

      await file.writeAsString(rawStringContent);

      final success = await importIptvFile(
        file: file,
        providerName: fileName,
        url: url,
        forceUpdate: forceUpdate,
        showTips: showTips,
        isHot: isHot,
      );
      if (await file.exists()) await file.delete();
      return success;
    } catch (e) {
      debugPrint("Network IPTV Download Failure: $e");
      if (showTips) {
        ToastUtil.show("网络订阅源下载或解析失败");
      }
      if (await file.exists()) await file.delete();
      return false;
    }
  }

  Future<bool> importFromWebString(
    String fileString,
    String fileName, {
    bool forceUpdate = false,
    bool showTips = true,
  }) async {
    try {
      final dir = await AppPathManager().getDir(AppPathManager.dirIptvCache);
      final file = File(p.join(dir.path, 'web_iptv_${FileUtils.generateUuid()}.m3u'));
      await file.writeAsString(fileString);

      // 彻底剥离 Web 字符串文件名的多重后缀
      String cleanName = p.basename(fileName);
      while (p.extension(cleanName).isNotEmpty) {
        cleanName = p.basenameWithoutExtension(cleanName);
      }
      fileName = cleanName;

      final success = await importIptvFile(
        file: file,
        providerName: fileName,
        forceUpdate: forceUpdate,
        showTips: showTips,
      );
      if (await file.exists()) await file.delete();
      return success;
    } catch (e) {
      if (showTips) {
        ToastUtil.show("网络订阅源下载或解析失败");
      }
      return false;
    }
  }

  Future<bool> importFromSharedMedia(dynamic media, {bool forceUpdate = false, bool showTips = true}) async {
    try {
      if (media.content == null || media.content!.isEmpty) {
        if (showTips) {
          ToastUtil.show("本地文件导入或解析失败");
        }
        return false;
      }

      File file = await FileUtils.convertPhysicalFile(media.content!);
      final ext = p.extension(file.path).toLowerCase();
      if (ext != '.m3u' && ext != '.txt') {
        if (showTips) {
          ToastUtil.show("不支持的文件格式，仅限 M3U 或 TXT");
        }
        return false;
      }

      final success = await importIptvFile(
        file: file,
        providerName: FileUtils.getBaseName(file.path),
        forceUpdate: forceUpdate,
        showTips: showTips,
      );
      return success;
    } catch (e) {
      debugPrint("Shared IPTV Import Process Crash: $e");
      if (showTips) {
        ToastUtil.show("本地文件导入或解析失败");
      }
      return false;
    }
  }

  Future<bool> importIptvFile({
    required File file,
    required String providerName,
    bool isHot = false,
    String url = '',
    bool forceUpdate = false,
    bool showTips = true,
  }) async {
    try {
      final ext = p.extension(file.path).toLowerCase();
      String content;
      try {
        final bytes = await file.readAsBytes();
        if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
          content = utf8.decode(bytes.sublist(3));
        } else {
          content = utf8.decode(bytes);
        }
      } catch (_) {
        final bytes = await file.readAsBytes();
        content = await CharsetConverter.decode("gbk", bytes);
      }

      String finalProviderId = isHot ? FileUtils.systemHotProviderId : FileUtils.generateUuid();
      final parsedResult = ext == '.txt'
          ? TxtParser().parse(content, providerId: finalProviderId)
          : M3uParser().parse(content, providerId: finalProviderId);

      if (parsedResult.channels.isEmpty) {
        if (showTips) {
          ToastUtil.show("不支持的文件格式，仅限 M3U 或 TXT");
        }
        return false;
      }

      final success = await _saveToDatabase(
        file: file,
        ext: ext,
        providerId: finalProviderId,
        providerName: providerName,
        isHot: isHot,
        url: url,
        channels: parsedResult.channels,
      );
      if (success) {
        if (showTips) ToastUtil.show("同步成功");
      } else {
        if (showTips) ToastUtil.show("同步失败");
      }
      return success;
    } catch (e) {
      debugPrint("IPTV Import Error: $e");
      if (showTips) {
        ToastUtil.show('${"同步失败"}: ${e.toString()}');
      }
      return false;
    }
  }

  Future<bool> _saveToDatabase({
    required File file,
    required String ext,
    required String providerId,
    required String providerName,
    required bool isHot,
    required String url,
    required List<dynamic> channels,
  }) async {
    try {
      final dir = await AppPathManager().getDir(AppPathManager.dirIptvCache);
      final savedFile = File(p.join(dir.path, '$providerId$ext'));
      final db = Get.find<DbService>().db;

      if (isHot && await savedFile.exists()) await savedFile.delete();
      await file.copy(savedFile.path);
      await db.deleteProviderAndChannels(providerId);

      final settings = Get.find<SettingsService>();
      await db.upsertProvider(
        database.ProvidersCompanion.insert(
          id: providerId,
          name: providerName.trim(),
          type: ext.replaceAll('.', ''),
          isAutoUpdate: drift.Value(url.isNotEmpty ? settings.isAutoSyncEnabled.value : false),
          url: drift.Value<String?>(url.isNotEmpty ? url : savedFile.path),
        ),
      );
      await db.upsertChannels(
        channels.map((e) {
          return database.ChannelsCompanion.insert(
            id: e.id,
            providerId: providerId,
            name: e.name,
            streamUrl: e.streamUrl,
            groupTitle: drift.Value(e.groupTitle),
            tvgId: drift.Value(e.tvgId),
            tvgName: drift.Value(e.tvgName),
            tvgLogo: drift.Value(e.tvgLogo),
          );
        }).toList(),
      );
      runAutoEpgMapping(providerId: providerId);
      return true;
    } catch (e) {
      debugPrint("Database Write Error: $e");
      return false;
    }
  }

  Future<void> runAutoEpgMapping({required String providerId}) async {
    try {
      final db = Get.find<DbService>().db;
      final String currentEpgSourceId = Get.find<SettingsService>().selectedSourceId.value;
      if (currentEpgSourceId.isEmpty) return;
      final channels = await db.getChannelsForProvider(providerId);
      final epgChannels = await db.getEpgChannelsForSource(currentEpgSourceId);
      if (channels.isEmpty || epgChannels.isEmpty) return;

      final cleanRegex = RegExp(r'[^a-zA-Z0-9\u4e00-\u9fa5]');
      List<database.EpgMappingsCompanion> mappingBatch = [];
      for (var ch in channels) {
        String? matchedEpgChannelId;
        final cleanTvgId = ch.tvgId?.trim().toLowerCase();
        final cleanChId = ch.id.trim().toLowerCase();
        final idMatch = epgChannels.firstWhereOrNull((dbCh) {
          final targetEpgId = dbCh.channelId.trim().toLowerCase();
          return (cleanTvgId != null && targetEpgId == cleanTvgId) || (targetEpgId == cleanChId);
        });

        if (idMatch != null) {
          matchedEpgChannelId = idMatch.id;
        } else {
          final targetClean = ch.name.toLowerCase().replaceAll(cleanRegex, '');
          final nameMatch = epgChannels.firstWhereOrNull((dbCh) {
            final dbChClean = dbCh.displayName.toLowerCase().replaceAll(cleanRegex, '');
            return targetClean.contains(dbChClean) || dbChClean.contains(targetClean);
          });

          if (nameMatch != null) {
            matchedEpgChannelId = nameMatch.id;
          }
        }
        if (matchedEpgChannelId != null) {
          mappingBatch.add(
            database.EpgMappingsCompanion.insert(
              channelId: ch.id,
              providerId: providerId,
              epgChannelId: matchedEpgChannelId,
              epgSourceId: currentEpgSourceId,
              source: const drift.Value('auto'),
            ),
          );
        }
      }

      if (mappingBatch.isNotEmpty) {
        await db.transaction(() async {
          final clearQuery = db.delete(db.epgMappings);
          clearQuery.where((t) => t.providerId.equals(providerId));
          await clearQuery.go();
          await db.upsertMappings(mappingBatch);
        });
        debugPrint("📊 [Auto Mapping] 成功在后台为该直播源全自动生成了 ${mappingBatch.length} 条 EPG 映射配对记录！");
      }
    } catch (e) {
      debugPrint("Auto Mapping runner process crashed: $e");
    }
  }
}
