import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const supportedLanguageCodes = <String>[
  'en',
  'zh',
  'es',
  'hi',
  'pt',
  'ru',
  'ja',
  'ko',
  'de',
  'fr',
  'tr',
  'vi',
  'id',
  'ar',
  'fa',
  'uk',
  'th',
  'fil',
  'it',
  'nl',
];

const supportedLocales = <Locale>[
  Locale('en'),
  Locale('zh'),
  Locale('es'),
  Locale('hi'),
  Locale('pt'),
  Locale('ru'),
  Locale('ja'),
  Locale('ko'),
  Locale('de'),
  Locale('fr'),
  Locale('tr'),
  Locale('vi'),
  Locale('id'),
  Locale('ar'),
  Locale('fa'),
  Locale('uk'),
  Locale('th'),
  Locale('fil'),
  Locale('it'),
  Locale('nl'),
];

const languageNames = <String, String>{
  'en': 'English',
  'zh': '简体中文',
  'es': 'Español',
  'hi': 'हिन्दी',
  'pt': 'Português',
  'ru': 'Русский',
  'ja': '日本語',
  'ko': '한국어',
  'de': 'Deutsch',
  'fr': 'Français',
  'tr': 'Türkçe',
  'vi': 'Tiếng Việt',
  'id': 'Bahasa Indonesia',
  'ar': 'العربية',
  'fa': 'فارسی',
  'uk': 'Українська',
  'th': 'ไทย',
  'fil': 'Filipino',
  'it': 'Italiano',
  'nl': 'Nederlands',
};

class AppStrings {
  const AppStrings(this.locale, this._values);

  final Locale locale;
  final Map<String, String> _values;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  String text(String key, [Map<String, Object> parameters = const {}]) {
    var value = _values[key] ?? key;
    for (final entry in parameters.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }

  static const delegate = _AppStringsDelegate();
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async {
    final code = isSupported(locale) ? locale.languageCode : 'en';
    final raw = await rootBundle.loadString('assets/i18n/$code.json');
    final values = (jsonDecode(raw) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as String),
    );
    return AppStrings(Locale(code), values);
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
