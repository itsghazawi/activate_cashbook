import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/format.dart';
import 'core/signer.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ActivatorApp());
}

class ActivatorApp extends StatelessWidget {
  const ActivatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Activate',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: buildTheme(Pal.lightPal),
        darkTheme: buildTheme(Pal.darkPal),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const PinScreen(),
      );
}

// ------------------------------------------------------------------ PIN
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  bool? _hasPin;
  String _entry = '';
  String? _first;
  String? _msg;
  bool _shake = false;

  @override
  void initState() {
    super.initState();
    Pin.hash().then((h) => setState(() => _hasPin = h != null));
  }

  Future<void> _tap(String d) async {
    HapticFeedback.selectionClick();
    if (d == '<') {
      if (_entry.isNotEmpty) setState(() => _entry = _entry.substring(0, _entry.length - 1));
      return;
    }
    if (_entry.length >= 4) return;
    setState(() {
      _entry += d;
      _msg = null;
    });
    if (_entry.length < 4) return;

    if (_hasPin == true) {
      if (await Pin.check(_entry)) {
        _enter();
      } else {
        _fail('رمز غير صحيح');
      }
    } else if (_first == null) {
      setState(() {
        _first = _entry;
        _entry = '';
      });
    } else if (_first == _entry) {
      await Pin.set(_entry);
      _enter();
    } else {
      setState(() => _first = null);
      _fail('الرمزان غير متطابقين، أعد المحاولة');
    }
  }

  void _fail(String m) {
    HapticFeedback.heavyImpact();
    setState(() {
      _msg = m;
      _entry = '';
      _shake = !_shake;
    });
  }

  void _enter() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => const HomeScreen(),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    if (_hasPin == null) return const Scaffold();
    final title = _hasPin! ? 'أدخل رمز الدخول' : (_first == null ? 'أنشئ رمز دخول من 4 أرقام' : 'أعد إدخال الرمز للتأكيد');
    Widget key(String d) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Material(
                color: d.isEmpty ? Colors.transparent : p.card,
                borderRadius: BorderRadius.circular(20),
                child: d.isEmpty
                    ? null
                    : InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _tap(d),
                        child: Center(
                          child: d == '<'
                              ? Icon(Icons.backspace_outlined, color: p.dim)
                              : Text(d,
                                  style: TextStyle(
                                      fontFamily: kHead, fontSize: 26, fontWeight: FontWeight.w600, color: p.text)),
                        ),
                      ),
              ),
            ),
          ),
        );
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const Spacer(),
              const _ActivatorMark(size: 76),
              const SizedBox(height: 18),
              Text('Activate',
                  style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w800, fontSize: 28, color: p.text)),
              Text('مفتاح تفعيل كاش بوك', style: TextStyle(color: p.gold, fontSize: 13)),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(color: p.dim)),
              const SizedBox(height: 26),
              TweenAnimationBuilder<double>(
                key: ValueKey(_shake),
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 400),
                builder: (_, v, child) => Transform.translate(
                  offset: Offset(12 * v * (((v * 10).floor() % 2 == 0) ? 1 : -1), 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final on = i < _entry.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 9),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? p.gold : Colors.transparent,
                        border: Border.all(color: on ? p.gold : p.faint, width: 1.6),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(
                height: 34,
                child: Center(child: Text(_msg ?? '', style: TextStyle(color: p.rose, fontSize: 13))),
              ),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '<'],
                  ])
                    Row(children: row.map(key).toList()),
                ]),
              ),
              const SizedBox(height: 12),
              Text('أيهم الغزاوي', style: TextStyle(fontFamily: kHead, color: p.gold, fontSize: 13)),
              const SizedBox(height: 14),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ActivatorMark extends StatelessWidget {
  final double size;
  const _ActivatorMark({this.size = 60});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: [BoxShadow(color: const Color(0xFFDDB872).withValues(alpha: 0.25), blurRadius: size * 0.4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset('assets/brand/icon.png', width: size, height: size, filterQuality: FilterQuality.high),
        ),
      );
}

// ------------------------------------------------------------------ HOME
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _device = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  List<Activation> _history = [];
  Activation? _result;
  String? _err;
  bool _busy = false;
  String _q = '';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    History.load().then((h) => setState(() => _history = h));
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text ?? '';
    // Pick the device code out of a whole WhatsApp message if needed.
    final m = RegExp(r'[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}').firstMatch(t);
    setState(() => _device.text = (m?.group(0) ?? t).trim().toUpperCase());
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (!Signer.validDevice(_device.text)) {
      setState(() => _err = 'كود الجهاز غير صحيح (16 حرفاً/رقماً)');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    final dev = Signer.pretty(_device.text);
    final code = await Signer.activationFor(dev);
    final a = Activation(device: dev, code: code, name: _name.text.trim(), phone: _phone.text.trim(), at: DateTime.now());
    _history.removeWhere((x) => x.device == dev);
    _history.insert(0, a);
    await History.save(_history);
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = false;
      _result = a;
    });
  }

  void _clear() {
    setState(() {
      _device.clear();
      _name.clear();
      _phone.clear();
      _result = null;
      _err = null;
    });
  }

  String _msgFor(Activation a) =>
      'أهلاً${a.name.isEmpty ? '' : ' ${a.name}'} 👋\nشكراً لاختيارك تطبيق كاش بوك.\n\nكود التفعيل الخاص بجهازك:\n${a.code}\n\nانسخه والصقه في خانة «كود التفعيل» ثم اضغط «تفعيل التطبيق».\n— أيهم الغزاوي';

  String _wa(String phone) {
    var d = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+')) return d.substring(1);
    if (d.startsWith('00')) return d.substring(2);
    if (d.startsWith('09')) return '963${d.substring(1)}';
    return d;
  }

  Future<void> _sendWhatsApp(Activation a) async {
    final text = Uri.encodeComponent(_msgFor(a));
    final uri = a.phone.isEmpty
        ? Uri.parse('https://wa.me/?text=$text')
        : Uri.parse('https://wa.me/${_wa(a.phone)}?text=$text');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      toast(context, 'تعذّر فتح واتساب', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(children: [
                const _ActivatorMark(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Activate',
                        style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w800, fontSize: 22, color: p.text)),
                    Text('مفتاح تفعيل كاش بوك · أيهم الغزاوي', style: TextStyle(color: p.dim, fontSize: 12)),
                  ]),
                ),
                Column(children: [
                  Text('${_history.length}',
                      style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w800, fontSize: 22, color: p.gold)),
                  Text('تفعيل', style: TextStyle(color: p.dim, fontSize: 11)),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Segmented<int>(
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
                items: [(0, 'توليد كود', null), (1, 'السجل (${_history.length})', null)],
              ),
            ),
            Expanded(child: _tab == 0 ? _generator(p) : _historyView(p)),
          ]),
        ),
      ),
    );
  }

  Widget _generator(Pal p) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          Surface(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('كود جهاز الزبون',
                  style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w700, color: p.text, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _device,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(fontFamily: kHead, fontSize: 20, letterSpacing: 2, color: p.gold, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                  errorText: _err,
                  suffixIcon: IconButton(icon: Icon(Icons.content_paste_rounded, color: p.gold), onPressed: _paste),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'اسم الزبون', prefixIcon: Icon(Icons.person_outline_rounded)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'رقمه', prefixIcon: Icon(Icons.phone_rounded)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              GoldButton(label: 'توليد كود التفعيل', icon: Icons.key_rounded, loading: _busy, onPressed: _generate),
            ]),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            FadeIn(child: _ResultCard(a: _result!, onSend: _sendWhatsApp, msgFor: _msgFor)),
            const SizedBox(height: 12),
            GhostButton(label: 'زبون جديد', icon: Icons.refresh_rounded, onPressed: _clear),
          ],
          const SizedBox(height: 22),
          Center(
            child: Text('⚠️ لا تشارك هذا التطبيق مع أحد — يحتوي على مفتاح التفعيل الخاص بك',
                textAlign: TextAlign.center, style: TextStyle(color: p.faint, fontSize: 11.5, height: 1.6)),
          ),
        ],
      );

  Widget _historyView(Pal p) {
    final list = _history
        .where((a) => _q.isEmpty || a.name.contains(_q) || a.phone.contains(_q) || a.device.contains(_q.toUpperCase()))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: TextField(
          onChanged: (v) => setState(() => _q = v.trim()),
          decoration: InputDecoration(hintText: 'بحث بالاسم أو الرقم أو كود الجهاز', prefixIcon: Icon(Icons.search_rounded, color: p.faint)),
        ),
      ),
      Expanded(
        child: list.isEmpty
            ? const EmptyState(icon: Icons.history_rounded, title: 'لا يوجد تفعيلات', subtitle: 'كل كود تولّده يُحفظ هنا تلقائياً')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final a = list[i];
                  return Surface(
                    padding: const EdgeInsets.all(14),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        child: SafeArea(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            SheetHeader(a.name.isEmpty ? 'تفعيل' : a.name, subtitle: fmtDateTime(a.at)),
                            _ResultCard(a: a, onSend: _sendWhatsApp, msgFor: _msgFor),
                          ]),
                        ),
                      ),
                    ),
                    onLongPress: () async {
                      if (await confirm(context, title: 'حذف من السجل؟', message: a.device, ok: 'حذف', danger: true)) {
                        setState(() => _history.remove(a));
                        await History.save(_history);
                      }
                    },
                    child: Row(children: [
                      Avatar(a.name.isEmpty ? '#' : a.name, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.name.isEmpty ? 'بدون اسم' : a.name,
                              style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w600, color: p.text)),
                          const SizedBox(height: 2),
                          Text(a.device,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(color: p.gold, fontSize: 12, letterSpacing: 1)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(fmtDateShort(a.at), style: TextStyle(color: p.dim, fontSize: 12)),
                        if (a.phone.isNotEmpty)
                          Text(a.phone, textDirection: TextDirection.ltr, style: TextStyle(color: p.faint, fontSize: 11.5)),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  final Activation a;
  final Future<void> Function(Activation) onSend;
  final String Function(Activation) msgFor;
  const _ResultCard({required this.a, required this.onSend, required this.msgFor});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Surface(
      gradient: LinearGradient(
        colors: [p.green.withValues(alpha: 0.16), p.green.withValues(alpha: 0.03)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      borderColor: p.green.withValues(alpha: 0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.verified_rounded, color: p.green),
          const SizedBox(width: 8),
          Text('كود التفعيل جاهز', style: TextStyle(fontFamily: kHead, fontWeight: FontWeight.w700, color: p.green)),
          const Spacer(),
          Text(a.device, textDirection: TextDirection.ltr, style: TextStyle(color: p.dim, fontSize: 11.5)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.dark ? const Color(0xFF0B1513) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.line),
          ),
          child: SelectableText(a.code,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontFamily: kBody, fontSize: 13.5, color: p.text, letterSpacing: 0.6, height: 1.5)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: GhostButton(
              label: 'نسخ',
              icon: Icons.copy_rounded,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: a.code));
                toast(context, 'تم نسخ كود التفعيل');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GhostButton(
              label: 'مشاركة',
              icon: Icons.ios_share_rounded,
              onPressed: () => SharePlus.instance.share(ShareParams(text: msgFor(a))),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        GoldButton(
          label: a.phone.isEmpty ? 'إرسال عبر واتساب' : 'إرسال إلى ${a.phone}',
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          textColor: Colors.white,
          onPressed: () => onSend(a),
        ),
      ]),
    );
  }
}
