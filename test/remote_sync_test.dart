import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/common/http_header_policy.dart';
import 'package:tv_remote_kit/tv_remote_kit.dart';

/// 局域网同步: the QR has to open a page, and the service has to admit it is running.
///
/// The reported bug was exactly the opposite: `start()` cleared its own running flag in
/// `finally`, so `isRunning` was false the moment it returned and the settings card spun
/// on "正在启动局域网同步服务器" forever while the server was up and serving.
class _RecordingDelegate extends RemoteSyncDelegate {
  final Map<String, Object?> applied = <String, Object?>{};
  Map<String, dynamic> exported = <String, dynamic>{'danmaku': <String, dynamic>{}};

  @override
  Future<Object?> channelState(String channel) async => null;

  @override
  Future<bool> applyChannel(String channel, Object? data) async {
    applied[channel] = data;
    return true;
  }

  @override
  Future<Map<String, dynamic>> exportSettings() async => exported;

  @override
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    exported = settings;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The test binding installs an HttpOverrides that answers every request with 400 and
    // never touches the network; this suite talks to the server the kit really starts.
    HttpOverrides.global = null;
  });

  Future<(TvRemoteKit, _RecordingDelegate)> startKit(WidgetTester tester) async {
    final delegate = _RecordingDelegate();
    // A free port range: the kit walks upwards from the port it is given.
    final kit = TvRemoteKit(deviceId: 'test-device', deviceName: 'PureLive TV (test)', delegate: delegate, port: 41234);
    await tester.runAsync(() => kit.start());
    addTearDown(() async {
      await tester.runAsync(() => kit.stop());
    });
    return (kit, delegate);
  }

  Future<(int status, String body)> request(
    WidgetTester tester,
    int port,
    String path, {
    String method = 'GET',
    String? body,
  }) async {
    final result = await tester.runAsync(() async {
      final client = HttpClient();
      try {
        final request = method == 'POST'
            ? await client.postUrl(Uri.parse('http://127.0.0.1:$port$path'))
            : await client.getUrl(Uri.parse('http://127.0.0.1:$port$path'));
        if (body != null) {
          // Without a charset the request sink encodes as Latin-1 and a Chinese search
          // term throws in the client, not in the server under test.
          request.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
          request.write(body);
        }
        final response = await request.close();
        return (response.statusCode, await utf8.decoder.bind(response).join());
      } finally {
        client.close(force: true);
      }
    });
    return result!;
  }

  testWidgets('a started kit reports itself as running and hands out a web address', (WidgetTester tester) async {
    final (kit, _) = await startKit(tester);

    expect(kit.isRunning, isTrue, reason: 'the settings card reads this to decide QR vs spinner');
    expect(kit.qrData, startsWith('http://'), reason: 'a camera scan has to open a browser');
    expect(kit.qrData, endsWith('/'));
    expect(kit.webAddress, kit.qrData);
    expect(kit.address, isNotEmpty, reason: 'ip:port stays available for manual entry');
  });

  testWidgets('the QR address serves the phone page', (WidgetTester tester) async {
    final (kit, _) = await startKit(tester);
    final port = Uri.parse(kit.qrData).port;

    final (status, html) = await request(tester, port, '/');

    expect(status, 200);
    expect(html, contains('<html'), reason: 'the browser gets a page, not JSON');
    // Every input the report named has to be on it.
    for (final field in <String>[
      'c_bilibili',
      'iptv_url',
      'iptv_headers',
      'p_host',
      'p_app_host',
      'streamer',
      'room',
      'filters',
      'tags',
    ]) {
      expect(html, contains(field), reason: 'missing input: $field');
    }
    expect(html, contains("'/api/channel/cookie'"));
    expect(html, contains("'/api/channel/iptv'"));
    expect(html, contains("saveChannel('proxy'"));
    expect(html, contains("'/api/search/'"));
  });

  testWidgets('a channel pushed from the page reaches the delegate', (WidgetTester tester) async {
    final (kit, delegate) = await startKit(tester);
    final port = Uri.parse(kit.qrData).port;

    final (status, body) = await request(
      tester,
      port,
      '/api/channel/proxy',
      method: 'POST',
      body: jsonEncode(<String, dynamic>{'enableProxy': true, 'proxyHost': '127.0.0.1', 'proxyPort': 7897}),
    );

    expect(status, 200);
    expect(jsonDecode(body)['data'], isTrue);
    expect(delegate.applied['proxy'], isA<Map<dynamic, dynamic>>());

    // The text inputs a phone pushes (search / room / movie) land as events.
    final events = <RemoteSyncEvent>[];
    final subscription = kit.events.where((event) => event is RemoteTextInputEvent).listen(events.add);
    addTearDown(subscription.cancel);

    await request(tester, port, '/api/search/streamer', method: 'POST', body: '张大仙');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));

    expect(events, isNotEmpty);
    expect((events.first as RemoteTextInputEvent).text, '张大仙');
  });

  testWidgets('the status endpoint identifies the device', (WidgetTester tester) async {
    final (kit, _) = await startKit(tester);
    final port = Uri.parse(kit.qrData).port;

    final (status, body) = await request(tester, port, '/api/remote-sync/status');

    expect(status, 200);
    final data = jsonDecode(body)['data'] as Map<String, dynamic>;
    expect(data['id'], 'test-device');
    expect(data['name'], 'PureLive TV (test)');
  });

  group('IPTV request headers', () {
    test('are written onto every entry as #EXTHTTP directives', () {
      const String playlist = '#EXTM3U\n#EXTINF:-1,CCTV1\nhttp://a/1.m3u8\n#EXTINF:-1,CCTV2\nhttp://a/2.m3u8\n';

      final String merged = HttpHeaderPolicy.mergeIntoM3u(playlist, <String, String>{
        'User-Agent': 'okhttp/3.12',
        'Referer': 'http://example.com/',
        'Cookie': 'a=b',
      });

      expect('#EXTHTTP:'.allMatches(merged).length, 2, reason: 'one directive per entry');
      expect(merged, contains('"user-agent":"okhttp/3.12"'), reason: 'names are canonicalised');
      expect(merged, contains('"referer":"http://example.com/"'));
      expect(merged, contains('"cookie":"a=b"'), reason: 'cookie needs #EXTHTTP, EXTVLCOPT cannot carry it');
      // Every directive must sit *before* its entry, which is where the parser reads it.
      expect(RegExp(r'#EXTHTTP:[^\n]*\n#EXTINF').allMatches(merged).length, 2);
    });

    test('leave a playlist untouched when there is nothing to add', () {
      const String playlist = '#EXTM3U\n#EXTINF:-1,CCTV1\nhttp://a/1.m3u8';
      expect(HttpHeaderPolicy.mergeIntoM3u(playlist, const <String, String>{}), playlist);
      expect(HttpHeaderPolicy.mergeIntoM3u(playlist, <String, String>{'  ': 'x'}), playlist);
    });
  });

  group('the web page source', () {
    test('covers every channel a phone form can write', () {
      // The page is a plain string in the kit; this pins that the sections the report
      // named are wired to the channels the delegate implements.
      for (final channel in <String>['cookie', 'iptv', 'proxy']) {
        expect(RemoteSyncProtocol.channels, contains(channel));
      }
    });
  });
}
