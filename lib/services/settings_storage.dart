import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  SettingsStorage._();
  static final SettingsStorage instance = SettingsStorage._();

  static const _kEndpoint = 'sos_ai_endpoint';
  static const _kAiWeight = 'sos_ai_weight';
  static const _kAlertThresh = 'sos_alert_thresh';
  static const _kAutoClipboard = 'sos_auto_clipboard';
  static const _kNativeBridge = 'sos_native_bridge';
  static const _kGbKey = 'sos_gb_key';
  static const _kVtKey = 'sos_vt_key';
  static const _kIntelSharing = 'sos_intel_sharing';

  SharedPreferences? _p;

  double alertThreshold = 0.52;
  double aiWeight = 0.55;
  String? aiEndpoint;
  bool autoClipboard = false;
  bool nativeAccessibilityBridge = true;
  /// مفتاح [Google Safe Browsing API](https://developers.google.com/safe-browsing) — لا يُرسل للخارج إلا لفحص الروابط.
  String googleSafeBrowsingApiKey = '';
  /// مفتاح [VirusTotal](https://www.virustotal.com/gui/my-apikey).
  String virusTotalApiKey = '';
  /// عند مشاركة رابط للتطبيق (Share): استخدام Google/VirusTotal إلى جانب المحلي والذكاء الاختياري.
  bool threatIntelWhenSharing = true;

  Future<void> load() async {
    _p ??= await SharedPreferences.getInstance();
    final p = _p!;
    alertThreshold =
        double.tryParse(p.getString(_kAlertThresh) ?? '') ?? alertThreshold;
    aiWeight =
        double.tryParse(p.getString(_kAiWeight) ?? '') ?? aiWeight;
    aiEndpoint = p.getString(_kEndpoint);
    autoClipboard = p.getBool(_kAutoClipboard) ?? false;
    nativeAccessibilityBridge = p.getBool(_kNativeBridge) ?? true;
    googleSafeBrowsingApiKey = p.getString(_kGbKey) ?? '';
    virusTotalApiKey = p.getString(_kVtKey) ?? '';
    threatIntelWhenSharing = p.getBool(_kIntelSharing) ?? true;
  }

  Future<void> save() async {
    _p ??= await SharedPreferences.getInstance();
    final p = _p!;
    await p.setString(_kAlertThresh, alertThreshold.toString());
    await p.setString(_kAiWeight, aiWeight.toString());
    if (aiEndpoint == null || aiEndpoint!.isEmpty) {
      await p.remove(_kEndpoint);
    } else {
      await p.setString(_kEndpoint, aiEndpoint!);
    }
    await p.setBool(_kAutoClipboard, autoClipboard);
    await p.setBool(_kNativeBridge, nativeAccessibilityBridge);
    await p.setString(_kGbKey, googleSafeBrowsingApiKey);
    await p.setString(_kVtKey, virusTotalApiKey);
    await p.setBool(_kIntelSharing, threatIntelWhenSharing);
  }
}
