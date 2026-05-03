import 'dart:async';

import 'package:app_links/app_links.dart';

import 'deep_link_resolver.dart';

/// الاستماع لروابط عميقة لفتح التطبيق وملء الفحص اليدوي.
class DeeplinkRegistrar {
  DeeplinkRegistrar._();
  static final DeeplinkRegistrar instance = DeeplinkRegistrar._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start() async {
    await _sub?.cancel();
    final initial = await _appLinks.getInitialLink();
    if (initial != null) ingestSecurityDeepLink(initial);
    _sub = _appLinks.uriLinkStream.listen(
      ingestSecurityDeepLink,
      onError: (_) {},
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
