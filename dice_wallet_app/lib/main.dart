import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'l10n/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final localeController = await LocaleController.load();
  runApp(DiceWalletApp(localeController: localeController));
}
