import 'dart:convert';

import 'package:http/http.dart' as http;

/// مكالمة [Google Safe Browsing v4 threatMatches:find](https://developers.google.com/safe-browsing/v4/reference/rest/v4/threatMatches/find).
/// يتطلب مفتاح API من Google Cloud (مفعّل عليه Safe Browsing API).
class SafeBrowsingService {
  SafeBrowsingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// يعيد `true` إن وُجد تطابق تهديد، `false` إن كان الرابط نظيفاً أو لم يُرجع الخادم تهديدات.
  /// يعيد `null` عند غياب المفتاح أو فشل الشبكة.
  Future<bool?> lookupThreat(String url, String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) return null;
    final uri = Uri.https(
      'safebrowsing.googleapis.com',
      '/v4/threatMatches:find',
      {'key': key},
    );
    final body = jsonEncode({
      'client': {
        'clientId': 'sound_of_safety',
        'clientVersion': '1.0.0',
      },
      'threatInfo': {
        'threatTypes': [
          'MALWARE',
          'SOCIAL_ENGINEERING',
          'UNWANTED_SOFTWARE',
          'POTENTIALLY_HARMFUL_APPLICATION',
        ],
        'platformTypes': ['ANY_PLATFORM'],
        'threatEntryTypes': ['URL'],
        'threatEntries': [
          {'url': url},
        ],
      },
    });
    try {
      final res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body);
        if (map is Map && map['matches'] is List) {
          return (map['matches'] as List).isNotEmpty;
        }
        return false;
      }
      if (res.statusCode == 429 || res.statusCode == 503) {
        return null;
      }
    } catch (_) {}
    return null;
  }

  void dispose() => _client.close();
}
