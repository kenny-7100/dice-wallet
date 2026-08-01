import 'dart:convert';

import 'package:flutter/services.dart';

class MnemonicTranslations {
  static final Map<String, Future<Map<String, String>>> _cache = {};

  static Future<Map<String, String>> load(String languageCode) =>
      _cache.putIfAbsent(languageCode, () async {
        final raw = await rootBundle.loadString(
          'assets/mnemonic/$languageCode.json',
        );
        return (jsonDecode(raw) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as String),
        );
      });
}
