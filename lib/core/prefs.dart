import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small app settings: theme + Face ID / fingerprint unlock.
class Prefs {
  Prefs._();

  static final theme = ValueNotifier<ThemeMode>(ThemeMode.dark);
  static final biometric = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    theme.value = switch (p.getString('theme')) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    biometric.value = p.getBool('bio') ?? false;
  }

  static Future<void> setTheme(ThemeMode m) async {
    theme.value = m;
    (await SharedPreferences.getInstance()).setString('theme', m.name);
  }

  static Future<void> setBiometric(bool v) async {
    biometric.value = v;
    (await SharedPreferences.getInstance()).setBool('bio', v);
  }
}

class Bio {
  Bio._();
  static final _auth = LocalAuthentication();

  /// True when the phone has Face ID / fingerprint set up.
  static Future<bool> available() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlock({String reason = 'افتح Activate بالبصمة'}) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }
}
