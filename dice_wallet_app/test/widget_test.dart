import 'package:dice_wallet_app/app.dart';
import 'package:dice_wallet_app/core/wallet_service.dart';
import 'package:dice_wallet_app/l10n/app_strings.dart';
import 'package:dice_wallet_app/l10n/locale_controller.dart';
import 'package:dice_wallet_app/screens/wallet_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('localized wallet creation experience works end to end', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final localeController = LocaleController(locale: const Locale('zh'));
    await tester.pumpWidget(DiceWalletApp(localeController: localeController));
    await tester.pumpAndSettle();

    expect(find.text('离线创建你的钱包'), findsOneWidget);
    expect(find.text('随机生成'), findsNWidgets(2));
    expect(find.text('抛硬币'), findsNWidgets(2));
    expect(find.text('12 词'), findsNWidgets(2));
    expect(find.text('24 词'), findsNWidgets(2));

    await tester.tap(find.text('抛硬币').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始记录'));
    await tester.pumpAndSettle();
    expect(find.text('第 1 次'), findsOneWidget);
    await tester.tap(find.text('正面'));
    await tester.pump();
    expect(find.text('1 / 128'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    expect(find.text('0 / 128'), findsOneWidget);

    Navigator.of(tester.element(find.text('0 / 128'))).pop();
    await tester.pumpAndSettle();
    await localeController.select(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
    expect(find.text('أنشئ محفظتك دون الاتصال بالإنترنت'), findsOneWidget);

    for (final code in supportedLanguageCodes) {
      await localeController.select(Locale(code));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'narrow layout: $code');
      expect(find.text('DICE WALLET'), findsOneWidget, reason: code);
    }

    await localeController.select(const Locale('zh'));
    await tester.pumpAndSettle();
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const wallet = DerivedWallet(
      mnemonic: mnemonic,
      addresses: [
        WalletAddress(
          'Bitcoin Native SegWit',
          bitcoinNativeSegwitPath,
          'bc1qexample',
        ),
        WalletAddress('Ethereum', ethereumPath, '0x1234'),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: supportedLocales,
        localizationsDelegates: [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: WalletResultScreen(wallet: wallet),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bitcoin Native SegWit'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('비트코인 네이티브 SegWit'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: supportedLocales,
        localizationsDelegates: [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: WalletResultScreen(wallet: wallet),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('敏感内容已隐藏'), findsOneWidget);
    expect(find.text('abandon'), findsNothing);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('abandon'), findsNWidgets(11));
    expect(find.text('about'), findsOneWidget);
    expect(find.text('放弃'), findsNWidgets(11));
    expect(find.text('关于'), findsOneWidget);
  });
}
