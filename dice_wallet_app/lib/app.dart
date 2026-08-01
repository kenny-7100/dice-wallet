import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'l10n/locale_controller.dart';
import 'screens/home_screen.dart';

class DiceWalletApp extends StatefulWidget {
  const DiceWalletApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  State<DiceWalletApp> createState() => _DiceWalletAppState();
}

class _DiceWalletAppState extends State<DiceWalletApp> {
  @override
  void initState() {
    super.initState();
    widget.localeController.addListener(_localeChanged);
  }

  @override
  void didUpdateWidget(DiceWalletApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeController != widget.localeController) {
      oldWidget.localeController.removeListener(_localeChanged);
      widget.localeController.addListener(_localeChanged);
    }
  }

  @override
  void dispose() {
    widget.localeController.removeListener(_localeChanged);
    super.dispose();
  }

  void _localeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17201C);
    const paper = Color(0xFFF4F3ED);
    const green = Color(0xFF176B4D);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dice Wallet',
      locale: widget.localeController.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.light,
          surface: paper,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
          fontFamily: 'sans-serif',
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFD9DCD7)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: HomeScreen(localeController: widget.localeController),
    );
  }
}
