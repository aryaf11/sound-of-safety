import 'dart:math';

/// مجموعة ميزات رياضية (مقياس ٠–١) تُطبَّق كطبقة شبيهة بتعلم الآلة قبل الدمج مع تحليل ذكاء اصطناعي اختياري.
class UrlFeatureEngine {
  /// جزء مسار بحث حقيقي (لا يعتبر '/' وحده وتجاهله كما لو كان فارغاً).
  static String _compactPathQuery(Uri u) {
    final raw = u.path;
    final segment = (raw.isEmpty || raw == '/') ? '' : raw;
    if (segment.isEmpty) {
      return u.query.isEmpty ? '' : '?${u.query}';
    }
    return u.query.isEmpty ? segment : '$segment?${u.query}';
  }

  static List<double> computeFeatureVector(Uri u, String raw) {
    final host = u.host.toLowerCase();
    final pqScan = _compactPathQuery(u);
    final segs =
        host.split('.').where((e) => e.isNotEmpty).map((s) => s.length).toList();

    double norm(num v, num max) =>
        max == 0 ? 0.0 : min(1.0, v.toDouble() / max.toDouble());

    final ipLike = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
    final hasAt = raw.contains('@');
    final httpOnly = u.scheme == 'http';
    final longHost = norm(host.length, 48);
    final subDepth = norm(max(0, segs.length - 2), 5);
    final hyphens = norm('-'.allMatches(host).length, 6);
    final digits = norm(RegExp(r'\d').allMatches(host).length, host.length.clamp(1, 999));

    final entropyBody = pqScan.isNotEmpty ? pqScan : host;
    final entropyCap = pqScan.isNotEmpty ? 5.6 : 7.05;
    final entropy = norm(_entropy(entropyBody), entropyCap);

    final sensitive = norm(_keywordHits(('$host$pqScan').toLowerCase()), 6);

    final queryLen = norm(u.query.length, 180);
    final puny =
        norm(host.startsWith('xn--') || host.contains(RegExp(r'[^\x00-\x7F]'))
            ? 1
            : 0,
            1);

    final vec = <double>[
      longHost,
      subDepth,
      hyphens,
      entropy,
      sensitive,
      queryLen,
      puny,
      ipLike ? 1.0 : 0,
      hasAt ? 1.0 : 0,
      digits,
      httpOnly ? 1.0 : 0,
    ];

    return vec;
  }

  static double logisticScore(List<double> x) {
    /// يجب أن يطابق طول السِّلسلة طول متجه الميزات؛ نقرأ بأمان حتى لا يطيح الفحص على الويب بسبب cache قديم أو اختلاف أبعاد.
    const w = <double>[
      0.18, 0.11, 0.14, 0.32, 0.53, 0.07,
      0.22, 0.38, 0.35, 0.12, 0.09,
    ];
    var dot = -0.32;
    for (var i = 0; i < w.length; i++) {
      final xi = i < x.length ? x[i] : 0.0;
      dot += w[i] * xi;
    }
    final s = _sigmoid(dot);
    return s.clamp(0.0, 1.0);
  }

  static List<String> explain(List<double> x, Uri u) {
    final reasons = <String>[];
    if (u.scheme == 'http') reasons.add('اتصال غير مشفَّر HTTP');
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(u.host)) {
      reasons.add('وجود عنوان آي بي مباشر');
    }
    if (RegExp('@').hasMatch(u.toString())) {
      reasons.add('احتمال نمط احتيالي يشمل رموز حساب');
    }
    if ('-'.allMatches(u.host.toLowerCase()).length >= 3) {
      reasons.add('نطاق فيه عدد فرط من الشرطات');
    }
    if (x.length > 4 && x[4] > 0.25) reasons.add('كلمات حساسة مرتبطة بالاحتيال');
    final pqExplain = _compactPathQuery(u);
    if (x.length > 3 && x[3] > 0.74 && pqExplain.isNotEmpty) {
      reasons.add('تعقيد مشبوه في المسار أو معاملات الاستعلام');
    }
    if ((u.host.split('.').length - 2) > 4) reasons.add('بنية نطاقات فرعية طويلة');
    return reasons;
  }

  static int _keywordHits(String s) {
    const suspicious = [
      'login', 'secure', 'verify', 'paypal', 'apple', 'bank', 'sms', 'gift',
      'password', 'update', 'account', 'confirm', 'wallet', 'crypto',
      'تسجيل', 'دخول', 'تحقق', 'بنك', 'حساب', 'جائزة', 'تحديث', 'أمن',
    ];
    var n = 0;
    for (final k in suspicious) {
      if (s.contains(k)) n++;
    }
    return n;
  }

  static double _entropy(String s) {
    if (s.isEmpty) return 0;
    final freq = <String, int>{};
    for (final ch in s.split('')) {
      freq[ch] = (freq[ch] ?? 0) + 1;
    }
    final len = s.length.toDouble();
    var h = 0.0;
    for (final c in freq.values) {
      final p = c / len;
      h -= p * log(p) / ln2;
    }
    return h;
  }

  static double _sigmoid(double z) => 1 / (1 + exp(-z));
}

class UrlAnalysisResult {
  UrlAnalysisResult({
    required this.riskScore,
    required this.reasons,
    required this.localMlScore,
    required this.aiScore,
    this.safeBrowsingThreat,
    this.virusTotalMaliciousBlend,
    this.userExplanation,
  });

  final double riskScore;
  final List<String> reasons;
  final double localMlScore;
  final double? aiScore;
  /// `true` تهديد وفق Safe Browsing، `false` عدم ظهور تطابق، `null` لم يُنفَّذ أو فشل.
  final bool? safeBrowsingThreat;
  /// مزيج خبيث/مشبوه من VirusTotal بين ٠ و١، أو `null`.
  final double? virusTotalMaliciousBlend;
  /// خلاصة مبسّطة لتفسير النتيجة (عربية) — مناسبة للقراءة و VoiceOver/TTS.
  final String? userExplanation;
}
