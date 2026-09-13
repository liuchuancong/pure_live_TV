import 'dart:async';

import 'package:dio/dio.dart';

/// TV 移植版：pure_live 的 PlaybackSourceTransport。
/// TV 项目没有 FFmpeg HLS relay / HlsSourceQueryPolicy 基础设施，
/// 因此这里去掉了 relay 分支与 policy 参数，保留输入租约（lease）、
/// 世代（generation）事务与取消语义，供 URL 源与 app 自有输入源使用。
// ignore_for_file: prefer_initializing_formals

typedef PlaybackInputFactory = Future<PlaybackInputLease> Function(String url, Map<String, String> headers);

/// Acquires exactly one caller-owned input, not a reusable bootstrap URL.
/// Observe cancellation and settle only after cleaning failed/partial creation.
/// Expected cancellation uses this token's Dio cancellation error; other
/// creation/cleanup failures remain visible to both open and joined teardown.
typedef PlaybackOwnedInputFactory = Future<PlaybackInputLease> Function(CancelToken cancel);
typedef PlaybackNativeOpen = Future<void> Function(
  String url,
  List<String> urls,
  Map<String, String> headers,
  bool privateInput,
);

/// One input resource; closing is idempotent, including pending/late opens.
class PlaybackInputLease {
  PlaybackInputLease(this.uri, Future<void> Function() close) : _close = close;
  final Uri uri;
  final Future<void> Function() _close;
  Future<void>? _closing;
  bool _closed = false;
  bool get isUsable => !_closed;
  Future<void> close() {
    _closed = true;
    return _closing ??= Future<void>.sync(_close);
  }
}

class _PlaybackInputCreation {
  _PlaybackInputCreation(this.joinOnCancel) {
    // open always observes the factory; teardown may also join it. Installing
    // an observer now avoids unhandled errors when no cancellation is pending.
    unawaited(settled.future.catchError((Object _) {}));
  }
  final bool joinOnCancel;
  final cancel = CancelToken();
  final settled = Completer<void>();
}

/// Owned by one UnifiedPlayer, not by the route or by a quality label.
/// Native completion can arrive after a manager deadline; its input must not
/// become active again after cancellation, replacement or disposal.
class PlaybackSourceTransport {
  PlaybackSourceTransport({PlaybackInputFactory? createInput}) : _createInput = createInput;
  final PlaybackInputFactory? _createInput;
  final Set<_PlaybackInputCreation> _creating = {};
  final Set<PlaybackInputLease> _pending = {};
  final Set<PlaybackInputLease> _retiring = {};
  PlaybackInputLease? _active;

  /// Remote session closure can invalidate a committed input before a user
  /// resumes. Consumers reacquire their recipe instead of replaying its URI.
  bool get activeInputIsUsable => !_closed && (_active?.isUsable ?? false);
  int _generation = 0;
  bool _closed = false;
  Future<void>? _closing;

  /// No placeholder URL, raw cookies or signed websocket are sent to native.
  /// Metadata/seat acquisition happens inside this same source transaction.
  Future<void> open({
    required String url,
    required List<String> urls,
    required Map<String, String> headers,
    required PlaybackNativeOpen nativeOpen,
  }) {
    final legacyFactory = _createInput;
    return _open(
      url: url,
      urls: urls,
      headers: headers,
      nativeOpen: nativeOpen,
      // Old injected factories have no cancellation contract; preserve their
      // late-result ownership without making close wait for arbitrary futures.
      joinCreationOnCancel: legacyFactory == null,
      createInput: legacyFactory == null
          ? null
          : (_) => legacyFactory(url, Map<String, String>.unmodifiable(headers)),
    );
  }

  Future<void> openOwned({required PlaybackOwnedInputFactory createInput, required PlaybackNativeOpen nativeOpen}) =>
      _open(createInput: createInput, joinCreationOnCancel: true, nativeOpen: nativeOpen);

  Future<void> _open({
    String? url,
    List<String> urls = const [],
    Map<String, String> headers = const {},
    required PlaybackOwnedInputFactory? createInput,
    required bool joinCreationOnCancel,
    required PlaybackNativeOpen nativeOpen,
  }) async {
    if (_closed) throw StateError('Playback input owner is closed');
    final generation = ++_generation;
    PlaybackInputLease? input;
    bool current() => !_closed && generation == _generation;
    try {
      if (_creating.isNotEmpty || _pending.isNotEmpty || _retiring.isNotEmpty) await _cancelPendingResources();
      if (!current()) throw StateError('Playback input transaction was retired');
      if (createInput != null) {
        input = await _acquire(createInput, current, joinOnCancel: joinCreationOnCancel);
      }
      if (!current() || input?.isUsable == false) throw StateError('Playback input transaction was retired');
      final local = input?.uri.toString();
      await nativeOpen(
        local ?? url!,
        local == null ? urls : [local],
        local == null ? headers : const {},
        input != null,
      );
      if (!current() || input?.isUsable == false) throw StateError('Playback input transaction was retired');
      final previous = _active;
      _active = input;
      _pending.remove(input);
      input = null;
      if (previous != null) await _retire(previous);
    } catch (_) {
      _pending.remove(input);
      if (input != null) await _retire(input);
      rethrow;
    }
  }

  Future<PlaybackInputLease> _acquire(
    PlaybackOwnedInputFactory factory,
    bool Function() current, {
    required bool joinOnCancel,
  }) async {
    final creation = _PlaybackInputCreation(joinOnCancel);
    _creating.add(creation);
    try {
      final input = await factory(creation.cancel);
      _pending.add(input);
      if (!current() || creation.cancel.isCancelled) {
        _pending.remove(input);
        await _retire(input);
        creation.settled.complete();
        throw StateError('Playback input transaction was retired');
      }
      creation.settled.complete();
      return input;
    } catch (error, stack) {
      if (!creation.settled.isCompleted) {
        if (creation.cancel.isCancelled && identical(error, creation.cancel.cancelError)) {
          creation.settled.complete();
        } else {
          creation.settled.completeError(error, stack);
        }
      }
      rethrow;
    } finally {
      _creating.remove(creation);
    }
  }

  /// Cancel only the pending replacement, retaining the previous input until
  /// its native owner is replaced or disposed. A late factory result is closed
  /// by open() without invoking nativeOpen; never await an unbounded native open.
  Future<void> cancelPending() async {
    _generation++;
    await _cancelPendingResources();
  }

  Future<void> _cancelPendingResources() async {
    final creating = _creating.toList();
    for (final creation in creating) {
      creation.cancel.cancel();
    }
    final pending = _pending.toList();
    _pending.clear();
    await Future.wait([
      ...pending.map(_retire),
      ..._retiring.map((input) => input.close()),
      for (final creation in creating)
        if (creation.joinOnCancel) creation.settled.future,
    ]);
  }

  Future<void> _retire(PlaybackInputLease input) async {
    _retiring.add(input);
    try {
      await input.close();
    } finally {
      _retiring.remove(input);
    }
  }

  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    _closed = true;
    final active = _active;
    _active = null;
    final pending = cancelPending();
    final activeClose = active == null ? Future<void>.value() : _retire(active);
    // A dispatch-time cancellation may already be retiring a native input.
    // Teardown still joins that cleanup instead of merely observing an empty
    // pending set and declaring the owner closed early.
    await Future.wait([pending, activeClose, ..._retiring.map((input) => input.close())]);
  }
}
