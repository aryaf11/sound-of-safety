import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/settings_storage.dart';

/// إعدادات متقدّمة وفصّالة عن الشاشة الرئيسية لتبقيها بسيطة للمكفوفين.
class IosSettingsScreen extends StatefulWidget {
  const IosSettingsScreen({super.key});

  @override
  State<IosSettingsScreen> createState() => _IosSettingsScreenState();
}

class _IosSettingsScreenState extends State<IosSettingsScreen> {
  final _endpointController = TextEditingController();
  final _gbKeyController = TextEditingController();
  final _vtKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SettingsStorage.instance.load();
    if (!mounted) return;
    setState(() {
      _endpointController.text = SettingsStorage.instance.aiEndpoint ?? '';
      _gbKeyController.text = SettingsStorage.instance.googleSafeBrowsingApiKey;
      _vtKeyController.text = SettingsStorage.instance.virusTotalApiKey;
    });
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _gbKeyController.dispose();
    _vtKeyController.dispose();
    super.dispose();
  }

  Future<void> _toggleClipboard(bool v) async {
    SettingsStorage.instance.autoClipboard = v;
    await SettingsStorage.instance.save();
    if (v) {
      try {
        await clipboardWatcher.start();
      } catch (e) {
        debugPrint('[صوت الأمان] clipboard_watcher.start: $e');
      }
    } else {
      await clipboardWatcher.stop();
    }
    setState(() {});
  }

  Future<void> _saveAi() async {
    final t = _endpointController.text.trim();
    SettingsStorage.instance.aiEndpoint = t.isEmpty ? null : t;
    await SettingsStorage.instance.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات خادم الذكاء')),
    );
  }

  Future<void> _saveKeys() async {
    SettingsStorage.instance.googleSafeBrowsingApiKey =
        _gbKeyController.text.trim();
    SettingsStorage.instance.virusTotalApiKey = _vtKeyController.text.trim();
    await SettingsStorage.instance.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ مفاتيح المصادر الخارجية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsStorage.instance;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'شاشة الإعدادات الإضافية',
          child: const Text('إعدادات إضافية'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile.adaptive(
            title: const Text(
              'فحص ما يُنسخ إلى الحافظة تلقائياً أثناء فتح التطبيق',
            ),
            subtitle: const Text(
              'على آي أو إس يعمل فقط وهذا التطبيق ظاهر بالكامل أمامك؛ لا يغطّي كل نظام الآيفون.',
            ),
            value: s.autoClipboard,
            onChanged: (v) => unawaited(_toggleClipboard(v)),
          ),
          const Divider(height: 28),
          Text(
            'خادم ذكاء اصطناعي اختياري',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              labelText: 'عنوان خادم التحليل (اختياري)',
              helperText:
                  'POST بتنسيق JSON يحوي حقل الرابط والرد ضمن risk أو score بين صفر وواحد',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'دمج المحلي مع الخادم: ${s.aiWeight.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: s.aiWeight,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (v) => setState(() => s.aiWeight = v),
            onChangeEnd: (v) async {
              SettingsStorage.instance.aiWeight = v;
              await SettingsStorage.instance.save();
            },
          ),
          const SizedBox(height: 6),
          Text(
            'عتبة التنبيه التلقائي (محلي): ${s.alertThreshold.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: s.alertThreshold,
            min: 0.2,
            max: 0.9,
            divisions: 14,
            onChanged: (v) => setState(() => s.alertThreshold = v),
            onChangeEnd: (v) async {
              SettingsStorage.instance.alertThreshold = v;
              await SettingsStorage.instance.save();
            },
          ),
          FilledButton(
            onPressed: () => unawaited(_saveAi()),
            child: const Text('حفظ إعدادات الذكاء'),
          ),
          const Divider(height: 28),
          Text(
            'مصادر خارجية (Safe Browsing و VirusTotal)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            title: const Text('استخدامها عند مشاركة نص للتطبيق'),
            value: s.threatIntelWhenSharing,
            onChanged: (v) async {
              SettingsStorage.instance.threatIntelWhenSharing = v;
              await SettingsStorage.instance.save();
              setState(() {});
            },
          ),
          TextField(
            controller: _gbKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'مفتاح Google Safe Browsing',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _vtKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'مفتاح VirusTotal',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: () => unawaited(_saveKeys()),
            child: const Text('حفظ المفاتيح'),
          ),
          const Divider(height: 28),
          Text(
            'Siri والروابط العميقة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'أنشئ اختصاراً في تطبيق «الاختصارات» يفتح هذا المخطّط مع الرابط المخصص بعد ترميزه:',
          ),
          const SizedBox(height: 10),
          SelectableText(
            'soundofsafety://scan?url=${Uri.encodeComponent('https://example.com')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final sample =
                  'soundofsafety://scan?url=${Uri.encodeComponent('https://example.com')}';
              Clipboard.setData(ClipboardData(text: sample));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم النسخ إلى الحافظة')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('نسخ مثال'),
          ),
        ],
      ),
    );
  }
}
