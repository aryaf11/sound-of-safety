import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../services/auth_storage.dart';
import '../../services/pending_scan_bridge.dart';
import '../../services/settings_storage.dart';
import '../../services/threat_guard.dart';
import '../../services/url_ai_orchestrator.dart';
import '../../services/url_feature_engine.dart';
import '../settings/ios_settings_screen.dart';

/// شاشة رئيسية مختصرة لتسهيل VoiceOver على آيفون.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ClipboardListener {
  final _urlCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _tts = FlutterTts();

  StreamSubscription<List<SharedMediaFile>>? _shareSub;
  VoidCallback? _pendingListen;

  UrlAnalysisResult? _last;
  bool _busy = false;
  bool _speaking = false;

  String _riskWord(double s) {
    if (s < 0.35) return 'مخاطرة منخفضة تقريباً';
    if (s < 0.55) return 'حذر متوسط';
    if (s < 0.75) return 'مخاطرة مرتفعة';
    return 'مخاطرة عالية جداً';
  }

  String _resultForVoiceOver(UrlAnalysisResult r) {
    final buf = StringBuffer()
      ..write('${_riskWord(r.riskScore)} ')
      ..write('درجة ${_formatPct(r.riskScore)}. ');
    final exp = (r.userExplanation ?? '').trim();
    if (exp.isNotEmpty) buf.write('$exp ');
    if (r.reasons.isNotEmpty) {
      buf.write('تفاصيل: ${r.reasons.take(8).join(' — ')}');
    }
    return buf.toString();
  }

  String _formatPct(double x) =>
      '${(x * 100).toStringAsFixed(0)} بالمئة';

  Future<void> _scrollBottom() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    clipboardWatcher.addListener(this);
    _pendingListen = _applyPendingDeepLink;
    PendingScanBridge.sharedUrl.addListener(_pendingListen!);
    _warmStart();
  }

  void _applyPendingDeepLink() {
    final v = PendingScanBridge.sharedUrl.value;
    if (v == null || v.trim().isEmpty) return;
    PendingScanBridge.sharedUrl.value = null;
    if (!mounted) return;
    setState(() => _urlCtrl.text = v.trim());
    SemanticsBinding.instance.ensureSemantics();
  }

  Future<void> _warmStart() async {
    await SettingsStorage.instance.load();
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.44);
    } catch (_) {}

    await _syncClipboardWatcher();

    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      await _onShare(initial);
      await ReceiveSharingIntent.instance.reset();
      _shareSub =
          ReceiveSharingIntent.instance.getMediaStream().listen((files) {
        unawaited(_onShare(files));
      });
    } catch (e, st) {
      debugPrint('[صوت الأمان] مشاركة: $e\n$st');
    }

    if (mounted) setState(() {});
  }

  Future<void> _syncClipboardWatcher() async {
    if (!SettingsStorage.instance.autoClipboard) {
      await clipboardWatcher.stop();
      return;
    }
    try {
      await clipboardWatcher.start();
    } catch (e) {
      debugPrint('[صوت الأمان] الحافظة: $e');
    }
  }

  Future<void> _onShare(List<SharedMediaFile> files) async {
    for (final f in files) {
      final parts = <String>[f.path];
      if ((f.message ?? '').trim().isNotEmpty) parts.add(f.message!);
      await ThreatGuard.instance.scanIfNeeded(
        parts.join('\n'),
        useThreatIntelApis: true,
      );
    }
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    if (_pendingListen != null) {
      PendingScanBridge.sharedUrl.removeListener(_pendingListen!);
    }
    clipboardWatcher.removeListener(this);
    unawaited(clipboardWatcher.stop());
    _urlCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void onClipboardChanged() async {
    if (!SettingsStorage.instance.autoClipboard) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text;
    if (t == null || t.isEmpty) return;
    await ThreatGuard.instance.scanIfNeeded(t);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => const IosSettingsScreen(),
      ),
    );
    await SettingsStorage.instance.load();
    await _syncClipboardWatcher();
    if (mounted) setState(() {});
  }

  Future<void> _analyze() async {
    FocusScope.of(context).unfocus();
    final raw = _urlCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('الصِق أو اكتب رابطاً قبل الفحص')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _last = null;
    });

    final st = SettingsStorage.instance;
    final useApis =
        st.googleSafeBrowsingApiKey.trim().isNotEmpty ||
            st.virusTotalApiKey.trim().isNotEmpty;

    UrlAnalysisResult? out;
    try {
      out = await UrlAiOrchestrator().analyze(
        raw,
        useRemoteAiLayer: true,
        useThreatIntelApis: useApis,
      );
    } catch (e, st_) {
      debugPrint('[صوت الأمان] فحص: $e');
      debugPrint('$st_');
      out = UrlAnalysisResult(
        riskScore: 0,
        reasons: const [
          'تعذّر الإكمال. تحقَّق من الاتصال والرابط ثم حاول مرّة ثانية',
        ],
        localMlScore: 0,
        aiScore: null,
        safeBrowsingThreat: null,
        virusTotalMaliciousBlend: null,
        userExplanation:
            'حدث خطأ تقني؛ أعد المحاولة لاحقاً أو تأكَّد من الاتصال.',
      );
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _last = out;
    });
    await _scrollBottom();
    SemanticsBinding.instance.ensureSemantics();
  }

  Future<void> _speakLast() async {
    final r = _last;
    if (r == null) return;
    final spoken = '${_resultForVoiceOver(r)} ${_formatPct(r.riskScore)}';
    setState(() => _speaking = true);
    try {
      await _tts.stop();
      await _tts.speak(spoken);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content:
                Text('لم تنجح القراءة الصوتية؛ تحقَّق من إعداد المتحدّث في آيفون'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _logout() async {
    await AuthStorage.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsStorage.instance;
    final name = AuthStorage.instance.state.username;
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label:
              name.isEmpty ? 'التطبيق صوت الأمان' : 'الشاشة الرئيسية لمستخدم اسمه $name',
          child: Text(name.isEmpty ? 'صوت الأمان' : 'مرحباً، $name'),
        ),
        actions: [
          Semantics(
            label: 'إعدادات إضافية وروابط وحافظة',
            button: true,
            child: IconButton(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_rounded),
            ),
          ),
          Semantics(
            label: 'تسجيل الخروج',
            button: true,
            child: IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
          children: [
            Text(
              'واحد: الصِق الرابط. اثنان: فحص الرابط. ثلاث: استمع للخلاصة إن أردت.',
              style: t.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 22),
            Semantics(
              textField: true,
              label: 'حقل رابط الإنترنت المراد فحصه',
              hint: 'أدخل عنواناً يبدأ غالباً بتي تي بي أس',
              child: TextField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => unawaited(_analyze()),
                decoration: const InputDecoration(
                  labelText: 'رابط لفحصه',
                  hintText: 'https://…',
                  helperText:
                      'يمكنك أيضاً إرسال الرابط من تطبيق آخر عبر زر المشاركة',
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_analyze()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_busy)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 12),
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  Text(_busy ? 'جاري الفحص' : 'فحص الرابط'),
                ],
              ),
            ),
            const SizedBox(height: 36),
            if (_last != null) ...[
              Semantics(
                container: true,
                liveRegion: true,
                label: _resultForVoiceOver(_last!),
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _last!.riskScore >= s.alertThreshold
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _last!.riskScore >= s.alertThreshold
                            ? const Color(0xFFC62828)
                            : const Color(0xFF2E7D32),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _last!.riskScore >= s.alertThreshold
                                ? 'قد يكون خطراً وفق هذا الفحص'
                                : 'يبدو أكثر أمناً وفق هذا الفحص',
                            style: t.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_riskWord(_last!.riskScore)} — ${_formatPct(_last!.riskScore)}',
                            style: t.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((_last!.userExplanation ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                (_last!.userExplanation ?? '').trim(),
                                style: t.textTheme.bodyLarge,
                              ),
                            ),
                          if (_last!.reasons.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _last!.reasons.join('\n'),
                                style: t.textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.tonal(
                onPressed:
                    (_speaking || _last == null) ? null : () => unawaited(_speakLast()),
                child: Text(_speaking ? 'يتحدث الآن…' : 'استمع للخلاصة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
