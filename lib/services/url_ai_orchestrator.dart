import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'safe_browsing_service.dart';
import 'settings_storage.dart';
import 'url_feature_engine.dart';
import 'virustotal_service.dart';

/// يضم نموذجاً محلياً شبيه التعلم الآلي + طبقة ذكاء اصطناعي عبر خادم (اختياري)
/// ومؤشرات خارجية ([Google Safe Browsing] و [VirusTotal]) عند توفر المفاتيح.
class UrlAiOrchestrator {
  UrlAiOrchestrator()
      : _sb = SafeBrowsingService(),
        _vt = VirusTotalService();

  final SettingsStorage _settings = SettingsStorage.instance;
  final SafeBrowsingService _sb;
  final VirusTotalService _vt;

  static final _urlPattern = RegExp(
    r'(https?:\/\/[^\s<>"()]+|www\.[^\s<>"()]+)',
    caseSensitive: false,
  );

  static List<Uri> extractUrls(String raw) {
    final out = <Uri>[];
    for (final m in _urlPattern.allMatches(raw)) {
      var s = m.group(0)!.trim();
      if (s.toLowerCase().startsWith('www.')) s = 'https://$s';
      try {
        final u = Uri.parse(s);
        if (u.hasScheme && u.host.isNotEmpty) out.add(u);
      } catch (_) {}
    }
    return out;
  }

  /// [useRemoteAiLayer]: خادم JSON اختياري.
  /// [useThreatIntelApis]: استدعاء Google Safe Browsing و VirusTotal إن وُجدت مفاتيح.
  Future<UrlAnalysisResult> analyze(
    String urlString, {
    bool useRemoteAiLayer = false,
    bool useThreatIntelApis = false,
  }) async {
    Uri u;
    try {
      u = Uri.parse(urlString.trim());
    } catch (_) {
      return UrlAnalysisResult(
        riskScore: 0,
        reasons: const [],
        localMlScore: 0,
        aiScore: null,
        safeBrowsingThreat: null,
        virusTotalMaliciousBlend: null,
        userExplanation:
            'تعذّر قراءة الرابط. تأكد من نسخه كاملاً بصيغة صحيحة مثل هتبس.',
      );
    }

    if (u.host.isEmpty) {
      return UrlAnalysisResult(
        riskScore: 0,
        reasons: const ['الرابط يفتقر إلى اسم مضيف صالح.'],
        localMlScore: 0,
        aiScore: null,
        safeBrowsingThreat: null,
        virusTotalMaliciousBlend: null,
        userExplanation:
            'لا يوجد عنوان نطاق واضح في الرابط؛ جرّب لصق رابط يبدأ بـ https ومضيف حقيقي.',
      );
    }

    final canonical = _canonicalUrl(u, urlString.trim());

    final vec = UrlFeatureEngine.computeFeatureVector(u, urlString);
    final local = UrlFeatureEngine.logisticScore(vec);
    final reasons = UrlFeatureEngine.explain(vec, u).toSet().toList();

    double? ai;
    final endpoint = _settings.aiEndpoint;
    if (useRemoteAiLayer && endpoint != null && endpoint.isNotEmpty) {
      ai = await _remoteAiScore(endpoint, canonical);
      if (ai != null && ai > 0.7) {
        reasons.add('تحذير من خادم تحليل ذكاء اصطناعي');
      }
    }

    double baseHybrid =
        useRemoteAiLayer ? _combine(local, ai, _settings.aiWeight) : local;

    bool? sbThreat;
    double? vtBlend;
    if (useThreatIntelApis) {
      final gbKey = _settings.googleSafeBrowsingApiKey.trim();
      final vtKey = _settings.virusTotalApiKey.trim();
      if (gbKey.isNotEmpty || vtKey.isNotEmpty) {
        final sbFuture = gbKey.isEmpty
            ? Future<bool?>.value(null)
            : _sb.lookupThreat(canonical, gbKey);
        final vtFuture = vtKey.isEmpty
            ? Future<double?>.value(null)
            : _vt.lookupMaliciousRatio(canonical, vtKey);
        sbThreat = await sbFuture;
        vtBlend = await vtFuture;
      }
    }

    if (sbThreat == true) {
      reasons.add(
        'تطابق ضمن قواعد تهديدات Google Safe Browsing (برمجيات خبيثة / تصيّد / خطر محتمل).',
      );
    } else if (sbThreat == false) {
      reasons.add('لم يُعثر على تطابق مباشر في Google Safe Browsing لهذا الرابط.');
    }

    if (vtBlend != null && vtBlend >= 0.08) {
      reasons.add(
        'تحليل VirusTotal يظهر مؤشراً خبيثاً أو مشبوهاً وفق مجموعة محركات الفحص.',
      );
    } else if (vtBlend != null && vtBlend < 0.08) {
      reasons.add(
        'مجموعة VirusTotal لم تُظهر مؤشرات قوية لخبيث عند تقرير المجموعة المتاح.',
      );
    }

    final intelBoost =
        (sbThreat == true ? 0.42 : 0.0) + (vtBlend ?? 0.0) * 0.38;

    double hybrid = (baseHybrid + intelBoost).clamp(0.0, 1.0);
    if (sbThreat == true || (vtBlend != null && vtBlend >= 0.35)) {
      hybrid = math.max(hybrid, baseHybrid * 0.35 + 0.5);
      hybrid = hybrid.clamp(0.0, 1.0);
    }

    if (hybrid >= 0.55 && reasons.isEmpty) {
      reasons.add('نمط غير عادي في الرابط أو في مجموعة المصادر المرجَعية');
    }

    final explanation = synthesizeArabicExplanation(
      baseHybridScore: baseHybrid,
      finalRiskScore: hybrid,
      localMl: local,
      aiScore: ai,
      sbThreat: sbThreat,
      vtMaliciousBlend: vtBlend,
      bulletReasons: reasons,
    );

    return UrlAnalysisResult(
      riskScore: hybrid,
      reasons: reasons,
      localMlScore: local,
      aiScore: ai,
      safeBrowsingThreat: sbThreat,
      virusTotalMaliciousBlend: vtBlend,
      userExplanation: explanation,
    );
  }

  double _combine(double local, double? ai, double wAi) {
    if (ai == null) return local;
    final wLoc = (1 - wAi).clamp(0.05, 0.95);
    return (wLoc * local + wAi * ai).clamp(0.0, 1.0);
  }

  static String _canonicalUrl(Uri u, String raw) {
    if (u.hasScheme &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty) {
      return u.removeFragment().toString();
    }
    var s = raw.trim();
    final lower = s.toLowerCase();
    if (!lower.startsWith('http')) {
      if (lower.startsWith('www.') || lower.contains('.')) {
        s = lower.startsWith('www.') ? 'https://$s' : 'https://$s';
      }
    }
    final again = Uri.tryParse(s);
    if (again != null &&
        again.hasScheme &&
        again.host.isNotEmpty &&
        (again.scheme == 'http' || again.scheme == 'https')) {
      return again.removeFragment().toString();
    }
    if (u.host.isNotEmpty) return u.removeFragment().toString();
    return raw.trim();
  }

  Future<double?> _remoteAiScore(String base, String url) async {
    final uri = Uri.tryParse(base);
    if (uri == null) return null;
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final map = jsonDecode(res.body);
      if (map is Map && map['risk'] is num) {
        return (map['risk'] as num).toDouble().clamp(0.0, 1.0);
      }
      if (map is Map && map['score'] is num) {
        return (map['score'] as num).toDouble().clamp(0.0, 1.0);
      }
    } catch (_) {}
    return null;
  }

  /// تفسير مبسّط للمستخدم وبمنطق شبيه الوكيل المعرفي: يصف السبب دون ادّعاء طرف ثالث.
  static String synthesizeArabicExplanation({
    required double baseHybridScore,
    required double finalRiskScore,
    required double localMl,
    required double? aiScore,
    required bool? sbThreat,
    required double? vtMaliciousBlend,
    required List<String> bulletReasons,
  }) {
    final pct = (finalRiskScore * 100).clamp(0, 100).toStringAsFixed(0);
    final localPct =
        (localMl * 100).clamp(0, 100).toStringAsFixed(0);

    final verdictIntro = finalRiskScore >= 0.55
        ? 'النتيجة المجمّعة مرتفعة نسبياً ($pct%). ننصح بالحذر وعدم إدخال بيانات حساسة قبل التحقق خارج التطبيق.'
        : 'النتيجة المجمّعة منخفضة نسبياً ($pct%) وفق هذا الجمع؛ يبقى الحذر مفيداً مع الروابط غير المتوقّعة.';

    final localLine =
        'التحليل المحلي المستند إلى ميزات الرابط يشير تقريباً إلى $localPct% كمقياس لمخاطرة شكلية.';

    final aiLine = aiScore == null
        ? ''
        : 'خادم الذكاء الاصطناعي الاختياري ساهم بدرجة مخاطرة تُقدَّر بحوالي ${(aiScore * 100).toStringAsFixed(0)}%.';

    String externalLine = '';
    if (sbThreat == null && vtMaliciousBlend == null) {
      externalLine =
          'لم تُفعَّل المصادر الخارجية (Safe Browsing / VirusTotal) أو لم يُجب الخادم؛ الاعتماد كان على المحلي والخادم الاختياري فقط.';
    } else {
      final parts = <String>[];
      if (sbThreat == true) {
        parts.add(
          'قاعدة بيانات Google Safe Browsing سجّلت هذا العنوان ضمن تهديد معروف',
        );
      } else if (sbThreat == false) {
        parts.add('لم يظهر هذا الرابط في نتيجة تهديد من Safe Browsing');
      }
      if (vtMaliciousBlend != null) {
        parts.add(
          'تجميع VirusTotal يقترح نسبة مؤشر مشبوه/خبيث تُقرَّب بـ ${(vtMaliciousBlend * 100).toStringAsFixed(0)}% من مجموع المحركات',
        );
      }
      externalLine =
          parts.isEmpty ? '' : '${parts.join('؛ ')}. هذه مصادر خارجية لتعزيز الدقة وليست ضماناً كاملاً.';
    }

    final hint = bulletReasons.isEmpty
        ? ''
        : 'أبرز الدلائل التقنية: ${bulletReasons.take(5).join(' — ')}.';

    return [
      verdictIntro,
      localLine,
      if (aiLine.isNotEmpty) aiLine,
      if (externalLine.isNotEmpty) externalLine,
      if (hint.isNotEmpty) hint,
      'خلاصة: المخاطرة المجمَّعة قبل الدمج الوسيط كان حوالي ${(baseHybridScore * 100).toStringAsFixed(0)}% ثم تعدِّل وفق المصادر المتاحة.',
    ].join(' ');
  }
}
