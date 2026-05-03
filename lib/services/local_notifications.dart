import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();

class LocalNotificationsService {
  static Future<void> init() async {
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );
  }

  /// طلب أذونات الإشعارات (آيفون؛ بدون تأثير على منصّات أخرى إن لم تُستخدم).
  static Future<bool> ensureNotificationPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final ok =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
    return ok;
  }

  /// تنبيه فوري لرابط خطير أو مشبوه (آي أو إس).
  static Future<void> showThreatAlert({
    required String url,
    required double riskScore,
    required List<String> reasons,
  }) async {
    final title = riskScore >= 0.65 ? 'رابط غير آمن' : 'رابط مشبوه';
    final detail = reasons.isNotEmpty ? reasons.first : 'تحقّق قبل المتابعة';

    await _plugin.show(
      url.hashCode & 0x7fffffff,
      title,
      '$detail — $url',
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          subtitle: '${(riskScore * 100).toStringAsFixed(0)}% مخاطرة تقديرية',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    if (riskScore >= 0.85) {
      debugPrint('[SOS HIGH RISK ${(riskScore * 100).toStringAsFixed(0)}%] $url');
    }
  }
}
