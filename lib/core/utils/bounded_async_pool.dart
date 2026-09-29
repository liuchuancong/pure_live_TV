import 'dart:math' as math;

/// Maps [items] through a bounded worker pool.
///
/// Unlike fixed `Future.wait` batches, each worker takes the next item as soon
/// as it finishes: one slow endpoint occupies a single worker instead of
/// stalling a whole batch.
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
