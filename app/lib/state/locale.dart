import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Every app language with its own name, in the order the picker shows them.
const appLanguages = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'it': 'Italiano',
  'pl': 'Polski',
  'pt': 'Português (Brasil)',
  'ru': 'Русский',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'ja': '日本語',
  'zh': '简体中文',
};

/// Where the chosen language is kept: this device only, so every device of a
/// player can speak its own language.
abstract class LocaleStore {
  Future<String?> load();
  Future<void> save(String? code);
}

class DeviceLocaleStore implements LocaleStore {
  static const _key = 'locale';

  @override
  Future<String?> load() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String? code) async {
    try {
      final p = await SharedPreferences.getInstance();
      code == null ? await p.remove(_key) : await p.setString(_key, code);
    } catch (_) {}
  }
}

final localeStoreProvider = Provider<LocaleStore>((ref) => DeviceLocaleStore());

/// The language the player picked, or null for the device language.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    Future.microtask(() async {
      final code = await ref.read(localeStoreProvider).load();
      if (code != null && supported(code)) state = Locale(code);
    });
    return null;
  }

  static bool supported(String code) =>
      appLanguages.containsKey(code) && AppLocalizations.supportedLocales.any((l) => l.languageCode == code);

  Future<void> set(String? code) async {
    state = code == null || !supported(code) ? null : Locale(code);
    await ref.read(localeStoreProvider).save(state?.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);
