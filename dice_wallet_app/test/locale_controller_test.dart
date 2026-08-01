import 'package:dice_wallet_app/l10n/locale_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language selection is the only remembered preference', () async {
    SharedPreferences.setMockInitialValues({});
    final firstRun = await LocaleController.load();
    expect(firstRun.locale, isNull);

    await firstRun.select(const Locale('ar'));
    final restarted = await LocaleController.load();
    expect(restarted.locale?.languageCode, 'ar');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {'language_code'});

    await restarted.select(null);
    final systemDefault = await LocaleController.load();
    expect(systemDefault.locale, isNull);
    expect(preferences.getKeys(), isEmpty);
  });

  test('unsupported stored language falls back to the system', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'xx'});
    final controller = await LocaleController.load();
    expect(controller.locale, isNull);
  });
}
