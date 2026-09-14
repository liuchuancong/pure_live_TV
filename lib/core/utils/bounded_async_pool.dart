import 'dart:math' as math;

/// 用有界 worker 池映射 [items]。
///
/// 与固定 `Future.wait` 分批不同，worker 完成后立即取下一项：
/// 一个慢端点只占一个 worker，不会阻塞下一批的所有请求。
/// （同步自 pure_live）
Future<List<R?>> boundedAsyncMap<T, R>(
  Iterable<T> items, {
  required int maxConcurrent,
  required Future<R?> Function(T item) task,
  bool Function()? shouldCancel,
}) async {
  final source = List<T>.of(items, growable: false);
  if (source.isEmpty) return <R?>[];

  final results = List<R?>.filled(source.length, null, growable: false);
  final workerCount = math.min(math.max(1, maxConcurrent), source.length);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      if (shouldCancel?.call() == true) return;
      final index = nextIndex++;
      if (index >= source.length) return;
      results[index] = await task(source[index]);
    }
  }

  await Future.wait(List<Future<void>>.generate(workerCount, (_) => worker()));
  return results;
}
