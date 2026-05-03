import 'dart:developer' as developer;

import 'local_notifications.dart';
import 'settings_storage.dart';
import 'url_ai_orchestrator.dart';

/// فحص موحّد مع منع التكرار السريع لنفس الرابط.
class ThreatGuard {
  ThreatGuard._();
  static final ThreatGuard instance = ThreatGuard._();

  final UrlAiOrchestrator _ai = UrlAiOrchestrator();
  String _lastKey = '';
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> scanIfNeeded(
    String candidate, {
    bool useThreatIntelApis = false,
  }) async {
    final trimmed = candidate.trim();
    final urls = UrlAiOrchestrator.extractUrls(trimmed);
    for (final u in urls) {
      await _analyzeOne(
        u.toString(),
        useThreatIntelApis: useThreatIntelApis,
      );
    }
  }

  Future<void> analyzeUrl(
    String urlString, {
    bool useThreatIntelApis = false,
  }) async {
    Uri? u;
    try {
      u = Uri.parse(urlString.trim());
      if (!(u.scheme == 'http' || u.scheme == 'https')) return;
      if (!u.hasAuthority) return;
    } catch (_) {
      return;
    }
    await _analyzeOne(
      u.toString(),
      useThreatIntelApis: useThreatIntelApis,
    );
  }

  Future<void> _analyzeOne(
    String canonical, {
    bool useThreatIntelApis = false,
  }) async {
    final threshold = SettingsStorage.instance.alertThreshold;
    final key = canonical;
    final now = DateTime.now();
    if (key == _lastKey && now.difference(_lastAt).inSeconds < 3) return;

    final wantApis = useThreatIntelApis &&
        SettingsStorage.instance.threatIntelWhenSharing &&
        (SettingsStorage.instance.googleSafeBrowsingApiKey.trim().isNotEmpty ||
            SettingsStorage.instance.virusTotalApiKey.trim().isNotEmpty);

    final result = await _ai.analyze(
      canonical,
      useThreatIntelApis: wantApis,
    );
    if (result.riskScore < threshold) return;

    _lastKey = key;
    _lastAt = now;

    developer.log(
      'Threat ${(result.riskScore * 100).toStringAsFixed(1)}%',
      name: 'SOS.scan',
      error: '${result.reasons}',
    );

    await LocalNotificationsService.ensureNotificationPermissions();
    await LocalNotificationsService.showThreatAlert(
      url: canonical,
      riskScore: result.riskScore,
      reasons: result.reasons,
    );
  }
}
