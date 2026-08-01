import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

const _languagePreferenceKey = 'language_code';

class LocaleController extends ChangeNotifier {
  LocaleController({Locale? locale, Future<void> Function(String?)? persist})
    : _locale = locale,
      _persist = persist;

  Locale? _locale;
  final Future<void> Function(String?)? _persist;

  Locale? get locale => _locale;

  static Future<LocaleController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_languagePreferenceKey);
    final locale = supportedLanguageCodes.contains(code) ? Locale(code!) : null;
    return LocaleController(
      locale: locale,
      persist: (value) async {
        if (value == null) {
          await preferences.remove(_languagePreferenceKey);
        } else {
          await preferences.setString(_languagePreferenceKey, value);
        }
      },
    );
  }

  Future<void> select(Locale? value) async {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    await _persist?.call(value?.languageCode);
  }
}
