/// 無限重試直到成功，指數退避（2s → 4s → 8s → ... → 30s 上限）
Future<T> retryUntilSuccess<T>(
  Future<T> Function() action, {
  Duration initialDelay = const Duration(seconds: 2),
  Duration maxDelay = const Duration(seconds: 30),
}) async {
  var delay = initialDelay;
  while (true) {
    try {
      return await action();
    } catch (_) {
      await Future.delayed(delay);
      if (delay < maxDelay) {
        delay = delay * 2;
        if (delay > maxDelay) delay = maxDelay;
      }
    }
  }
}
