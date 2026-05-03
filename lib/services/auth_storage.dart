import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_state.dart';

/// تخزين محلي لحالة التسجيل والتحقق من البريد (تجريبي بدون خادم).
class AuthStorage extends ChangeNotifier {
  AuthStorage._();
  static final AuthStorage instance = AuthStorage._();

  static const _kUser = 'sos_username';
  static const _kEmail = 'sos_email';
  static const _kRegDone = 'sos_reg_complete';
  static const _kEmailOk = 'sos_email_verified';
  static const _kPendingCode = 'sos_pending_code';
  static const _kPasswordHash = 'sos_pwd_hash';

  AuthSaveState state = const AuthSaveState(
    username: '',
    email: '',
    completedRegistration: false,
    emailVerified: false,
  );

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final p = _prefs!;
    state = AuthSaveState(
      username: p.getString(_kUser) ?? '',
      email: p.getString(_kEmail) ?? '',
      completedRegistration: p.getBool(_kRegDone) ?? false,
      emailVerified: p.getBool(_kEmailOk) ?? false,
    );
    notifyListeners();
  }

  /// يولّد كود تحقق ويُحفظ للمقارنة عند الإدخال (بدون SMTP في الوضع التجريبي).
  String prepareEmailVerificationCode() {
    final code = Random().nextInt(900000 + 1).toString().padLeft(6, '0');
    _prefs?.setString(_kPendingCode, code);
    if (kDebugMode) {
      debugPrint('[صوت الأمان] كود التحقق التجريبي: $code');
    }
    return code;
  }

  bool verifyEmailCode(String input) {
    final expected = _prefs?.getString(_kPendingCode) ?? '';
    final ok = input.trim() == expected && expected.isNotEmpty;
    if (ok) {
      _prefs?.setBool(_kEmailOk, true);
      state = state.copyWith(emailVerified: true);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> login(String email, String password) async {
    await load();
    final p = _prefs;
    if (p == null) return false;
    final storedEmail = (p.getString(_kEmail) ?? '').toLowerCase();
    if (storedEmail != email.trim().toLowerCase()) return false;
    final hash = p.getString(_kPasswordHash);
    if (hash == null) return false;
    final candidate = hashPassword(password);
    if (candidate != hash) return false;
    await p.setBool(_kRegDone, true);
    await p.setBool(_kEmailOk, true);
    state = state.copyWith(completedRegistration: true, emailVerified: true);
    notifyListeners();
    return true;
  }

  Future<void> completeRegistration({
    required String username,
    required String email,
    required String password,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final p = _prefs!;
    await p.setString(_kUser, username.trim());
    await p.setString(_kEmail, email.trim().toLowerCase());
    await p.setBool(_kRegDone, true);
    await p.setBool(_kEmailOk, false);
    await p.setString(_kPasswordHash, hashPassword(password));
    await p.remove(_kPendingCode);
    state = AuthSaveState(
      username: username.trim(),
      email: email.trim().toLowerCase(),
      completedRegistration: true,
      emailVerified: false,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
    state = const AuthSaveState(
      username: '',
      email: '',
      completedRegistration: false,
      emailVerified: false,
    );
    notifyListeners();
  }

  static String hashPassword(String raw) {
    return base64Encode(utf8.encode('sos|$raw'));
  }
}
