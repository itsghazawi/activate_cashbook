import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/backup.dart';
import 'core/prefs.dart';
import 'core/signer.dart';
import 'main.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class SettingsScreen extends StatefulWidget {
  final List<Activation> Function() history;
  final Future<void> Function(List<Activation>) onHistory;
  const SettingsScreen({super.key, required this.history, required this.onHistory});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    Bio.available().then((v) {
      if (mounted) setState(() => _bioAvailable = v);
    });
  }

  Future<void> _import(String title) async {
    try {
      final r = await LogBackup.pickAndMerge(widget.history(), title: title);
      if (r == null) return;
      await widget.onHistory(r.$1);
      if (mounted) {
        setState(() {});
        toast(context, 'تم استيراد ${r.$2} تفعيل');
      }
    } catch (_) {
      if (mounted) toast(context, 'الملف غير صالح', error: true);
    }
  }

  Future<void> _toggleBio(bool v) async {
    if (v) {
      if (!_bioAvailable) {
        toast(context, 'فعّل بصمة الوجه أو الإصبع من إعدادات الهاتف أولاً', error: true);
        return;
      }
      final ok = await Bio.unlock(reason: 'تأكيد تفعيل الدخول بالبصمة');
      if (!ok) return;
    }
    await Prefs.setBiometric(v);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final h = widget.history();
    final now = DateTime.now();
    final today = h.where((a) => a.at.year == now.year && a.at.month == now.month && a.at.day == now.day).length;
    final month = h.where((a) => a.at.year == now.year && a.at.month == now.month).length;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: AppBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 30 + MediaQuery.of(context).viewPadding.bottom),
          children: [
            Row(children: [
              Expanded(child: _Stat(label: 'اليوم', value: today, color: p.green)),
              const SizedBox(width: 10),
              Expanded(child: _Stat(label: 'هذا الشهر', value: month, color: p.gold)),
              const SizedBox(width: 10),
              Expanded(child: _Stat(label: 'الكل', value: h.length, color: p.blue)),
            ]),
            const SectionHeader('الأمان'),
            _Group(children: [
              _Item(
                icon: Icons.face_rounded,
                title: 'الدخول ببصمة الوجه / الإصبع',
                value: _bioAvailable ? 'Face ID أو البصمة بدل كتابة الرمز' : 'غير متاحة على هذا الهاتف',
                trailing: Switch(value: Prefs.biometric.value, onChanged: _toggleBio),
              ),
              _Item(
                icon: Icons.password_rounded,
                title: 'تغيير رمز الدخول',
                value: 'أدخل الرمز الجديد مباشرة',
                onTap: () async {
                  final ok = await Navigator.push<bool>(
                      context, MaterialPageRoute(builder: (_) => const PinScreen(changeMode: true)));
                  if (ok == true && context.mounted) toast(context, 'تم تغيير رمز الدخول ✓');
                },
              ),
            ]),
            const SectionHeader('Google Drive'),
            _Group(children: [
              _Item(
                icon: Icons.add_to_drive_rounded,
                title: 'نسخ السجل إلى Google Drive',
                value: 'من القائمة اختر تطبيق Drive واحفظ الملف',
                onTap: () async {
                  if (h.isEmpty) return toast(context, 'السجل فارغ');
                  await LogBackup.toDrive(h);
                },
              ),
              _Item(
                icon: Icons.cloud_download_rounded,
                title: 'استيراد من Google Drive',
                value: 'افتح Drive من نافذة الملفات واختر ملف النسخة',
                onTap: () => _import('اختر ملف النسخة من Google Drive'),
              ),
            ]),
            const SectionHeader('الهاتف'),
            _Group(children: [
              _Item(
                icon: Icons.save_alt_rounded,
                title: 'حفظ نسخة على الهاتف',
                value: 'اختر مكان الحفظ (الملفات / iCloud / التنزيلات)',
                onTap: () async {
                  if (h.isEmpty) return toast(context, 'السجل فارغ');
                  try {
                    if (await LogBackup.toPhone(h) && context.mounted) toast(context, 'تم حفظ النسخة ✓');
                  } catch (_) {
                    if (context.mounted) toast(context, 'تعذّر الحفظ', error: true);
                  }
                },
              ),
              _Item(
                icon: Icons.restore_page_rounded,
                title: 'استيراد من الهاتف',
                value: 'اختر ملف النسخة (.json)',
                onTap: () => _import('اختر ملف نسخة السجل'),
              ),
            ]),
            const SectionHeader('المظهر'),
            _Group(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Segmented<ThemeMode>(
                  value: Prefs.theme.value,
                  onChanged: (m) async {
                    await Prefs.setTheme(m);
                    setState(() {});
                  },
                  items: const [
                    (ThemeMode.dark, 'داكن', null),
                    (ThemeMode.light, 'فاتح', null),
                    (ThemeMode.system, 'تلقائي', null),
                  ],
                ),
              ),
            ]),
            const SectionHeader('حول'),
            Surface(
              child: Column(children: [
                Image.asset('assets/brand/icon.png', width: 56, height: 56),
                const SizedBox(height: 10),
                Text('Activate', style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w800, fontSize: 20, color: p.text)),
                Text('مفتاح تفعيل كاش بوك', style: TextStyle(color: p.dim, fontSize: 12.5)),
                const SizedBox(height: 10),
                Text('أيهم الغزاوي', style: TextStyle(fontFamily: kHead, color: p.gold, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://alghazawi.me'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: const Text('alghazawi.me'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Surface(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(children: [
        Text('$value', style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w800, fontSize: 24, color: color)),
        Text(label, style: TextStyle(color: p.dim, fontSize: 12)),
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) items.add(Divider(height: 1, indent: 58, color: p.line));
    }
    return Surface(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: items));
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _Item({required this.icon, required this.title, required this.value, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: p.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: p.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: p.dim, fontSize: 12)),
            ]),
          ),
          trailing ?? (onTap != null ? Icon(Icons.chevron_left_rounded, color: p.faint) : const SizedBox.shrink()),
        ]),
      ),
    );
  }
}
