import 'dart:convert';

import 'package:http/http.dart' as http;

/// بحث تقرير URL عبر [VirusTotal v3 URLs API](https://developers.virustotal.com/reference/get-a-url-analysis-report).
/// المفتاح في رأس الطلب `x-apikey`.
class VirusTotalService {
  VirusTotalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String urlId(String url) {
    final raw = utf8.encode(url);
    final b64 = base64Encode(raw);
    return b64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  /// يعيد نسبة مكوّنات خبيثة/مشبوهة من إجمالي المحركات عند النجاح (٠–١)، أو `null`.
  Future<double?> lookupMaliciousRatio(String url, String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) return null;
    final id = urlId(url);
    final uri = Uri.parse('https://www.virustotal.com/api/v3/urls/$id');
    try {
      final res =
          await _client.get(uri, headers: _headers(key)).timeout(const Duration(seconds: 14));
      if (res.statusCode == 404) {
        await _enqueueUrlLookup(url, key);
        await Future<void>.delayed(const Duration(seconds: 3));
        final res2 =
            await _client.get(uri, headers: _headers(key)).timeout(const Duration(seconds: 14));
        return _parseStats(res2);
      }
      return _parseStats(res);
    } catch (_) {}
    return null;
  }

  static Map<String, String> _headers(String apiKey) {
    return {
      'x-apikey': apiKey,
      'Accept': 'application/json',
    };
  }

  Future<void> _enqueueUrlLookup(String url, String apiKey) async {
    final body =
        utf8.encode('url=${Uri.encodeQueryComponent(url)}');
    await _client.post(
      Uri.parse('https://www.virustotal.com/api/v3/urls'),
      headers: {
        ..._headers(apiKey),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    ).timeout(const Duration(seconds: 10));
  }

  /// يفك JSON stats من استجابة GET /urls/{id}
  double? _parseStats(http.Response res) {
    if (res.statusCode != 200) return null;
    Map? map;
    try {
      map = jsonDecode(res.body);
    } catch (_) {
      return null;
    }
    if (map is! Map) return null;
    final data = map['data'];
    if (data is! Map) return null;
    final attrs = data['attributes'];
    if (attrs is! Map) return null;
    final stats = attrs['last_analysis_stats'];
    if (stats is! Map) return null;
    final m = _asInt(stats['malicious']);
    final s = _asInt(stats['suspicious']);
    final h = _asInt(stats['harmless']);
    final u = _asInt(stats['undetected']);
    final total = m + s + h + u;
    if (total <= 0) return null;
    return ((m + s * 0.45) / total).clamp(0.0, 1.0);
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  void dispose() => _client.close();
}
