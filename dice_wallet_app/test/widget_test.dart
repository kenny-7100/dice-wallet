import 'package:dice_wallet_app/app.dart';
import 'package:dice_wallet_app/core/wallet_service.dart';
import 'package:dice_wallet_app/screens/wallet_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home exposes all four wallet creation flows', (tester) async {
    await tester.pumpWidget(const DiceWalletApp());

    expect(find.text('离线创建你的钱包'), findsOneWidget);
    expect(find.text('随机生成'), findsNWidgets(2));
    expect(find.text('抛硬币'), findsNWidgets(2));
    expect(find.text('12 词'), findsNWidgets(2));
    expect(find.text('24 词'), findsNWidgets(2));
  });

  testWidgets('coin flip flow records, labels, and undoes results', (
    tester,
  ) async {
    await tester.pumpWidget(const DiceWalletApp());
    await tester.tap(find.text('抛硬币').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始记录'));
    await tester.pumpAndSettle();

    expect(find.text('第 1 次'), findsOneWidget);
    await tester.tap(find.text('正面'));
    await tester.pump();
    expect(find.text('1 / 128'), findsOneWidget);
    expect(find.text('正'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    expect(find.text('0 / 128'), findsOneWidget);
  });

  testWidgets('wallet result hides mnemonic until explicitly revealed', (
    tester,
  ) async {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const wallet = DerivedWallet(
      mnemonic: mnemonic,
      addresses: [WalletAddress('Ethereum', ethereumPath, '0x1234')],
    );
    await tester.pumpWidget(
      const MaterialApp(home: WalletResultScreen(wallet: wallet)),
    );

    expect(find.text('敏感内容已隐藏'), findsOneWidget);
    expect(find.text('abandon'), findsNothing);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('abandon'), findsNWidgets(11));
    expect(find.text('about'), findsOneWidget);
    expect(find.text('放弃'), findsNWidgets(11));
    expect(find.text('关于'), findsOneWidget);
  });
}
