import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates Cash Book activation codes. KEEP THIS APP PRIVATE —
/// it contains the private signing key.
class Signer {
  static const _seed = 'Cq1IJPAQeSvWrjnbCumTNSLJZ4H77AKMHqOJ+/1+pD8=';
  static KeyPair? _kp;

  static String normalize(String c) => c.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');

  static bool validDevice(String c) => RegExp(r'^[0-9A-HJKMNP-TV-Z]{16}$').hasMatch(normalize(c));

  static String pretty(String c) {
    final n = normalize(c);
    if (n.length != 16) return n;
    return '${n.substring(0, 4)}-${n.substring(4, 8)}-${n.substring(8, 12)}-${n.substring(12)}';
  }

  static Future<String> activationFor(String deviceCode) async {
    _kp ??= await Ed25519().newKeyPairFromSeed(base64.decode(_seed));
    final sig = await Ed25519().sign(utf8.encode('CASHBOOK|LIC|v1|${normalize(deviceCode)}'), keyPair: _kp!);
    return base64Url.encode(sig.bytes).replaceAll('=', '');
  }
}

class Activation {
  final String device;
  final String code;
  final String name;
  final String phone;
  final DateTime at;
  Activation({required this.device, required this.code, required this.name, required this.phone, required this.at});

  Map<String, dynamic> toJson() =>
      {'device': device, 'code': code, 'name': name, 'phone': phone, 'at': at.toIso8601String()};
  factory Activation.fromJson(Map<String, dynamic> j) => Activation(
        device: j['device'],
        code: j['code'],
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        at: DateTime.parse(j['at']),
      );
}

class History {
  static Future<List<Activation>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('history');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Activation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> save(List<Activation> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('history', jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}

class Pin {
  static Future<String?> hash() async => (await SharedPreferences.getInstance()).getString('pin');

  static Future<String> digest(String pin) async {
    final h = await Sha256().hash(utf8.encode('cb-activator|$pin'));
    return base64.encode(h.bytes);
  }

  static Future<void> set(String pin) async =>
      (await SharedPreferences.getInstance()).setString('pin', await digest(pin));

  static Future<bool> check(String pin) async => (await hash()) == await digest(pin);
}
