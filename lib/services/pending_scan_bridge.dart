import 'package:flutter/foundation.dart';

/// رابط لفحصه يدوياً بعد فتح التطبيق عبر مخطّط عميق أو اختصار Siri قصيرة.
class PendingScanBridge {
  PendingScanBridge._();

  /// آخر عنوان جاهز لتعبئة حقل الفحص اليدوي (يُستهلك من شاشة الرئيسية ويُصفَّر بعد الاستخدام).
  static ValueNotifier<String?> sharedUrl = ValueNotifier<String?>(null);

  static void offer(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    sharedUrl.value = t;
    if (kDebugMode) debugPrint('[صوت الأمان] رابط مؤجل للفحص: $t');
  }
}
