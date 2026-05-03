import 'pending_scan_bridge.dart';

/// يحوّل `soundofsafety://…` أو `sosafety://…` إلى رابط لفحصه.
///
/// الأمثلة: `soundofsafety://scan?url=https%253A...` أو `soundofsafety://scan?target=...`.
void ingestSecurityDeepLink(Uri u) {
  final schemeOk =
      u.scheme == 'soundofsafety' || u.scheme == 'sosafety';
  if (!schemeOk) return;

  var target = u.queryParameters['url'] ?? u.queryParameters['target'];
  target = Uri.decodeComponent(target ?? '');
  if (target.isEmpty && u.hasQuery) {
    final raw = u.query;
    if (raw.startsWith('url=')) {
      target = Uri.decodeComponent(raw.substring(4));
    }
  }
  PendingScanBridge.offer(target.trim());
}
