import 'dart:typed_data';

import 'package:dice_wallet_app/core/mnemonic_translations.dart';
import 'package:dice_wallet_app/core/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = WalletService();

  test('derives the Node 24-word zero-entropy wallet vector', () async {
    final wallet = await service.derive(Uint8List(32));

    expect(wallet.mnemonic, '${'abandon ' * 23}art');
    expect(wallet.addresses.map((item) => item.address), [
      'bc1qzmtrqsfuaf6l6kkcsseumq26ukaphfj9skkug6',
      'bc1p68a8a3vuv2cxzs7e2gjc5v3qy3zdnfaxwftyqe9k9nquvm6r4w2ssldtzp',
      '0xF278cF59F82eDcf871d630F28EcC8056f25C1cdb',
      '3Cy3YNTFywCmxoxt8n7UH6hg6dLo5uACowX3CFceaSnx',
      'TEfhiqsW1SdN44DeHrAWVmbyr8ZbvChrtS',
    ]);
  });

  test('derives the Node 12-word zero-entropy wallet vector', () async {
    final wallet = await service.derive(Uint8List(16));

    expect(wallet.mnemonic, '${'abandon ' * 11}about');
    expect(wallet.addresses.map((item) => item.address), [
      'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu',
      'bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr',
      '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
      'HAgk14JpMQLgt6rVgv7cBQFJWFto5Dqxi472uT3DKpqk',
      'TUEZSdKsoDHQMeZwihtdoBiN46zxhGWYdH',
    ]);
  });

  test('coin flip mapping matches the CLI', () {
    expect(service.entropyFromCoinFlips(List.filled(128, true)), Uint8List(16));
    expect(
      service.entropyFromCoinFlips(List.filled(128, false)),
      Uint8List.fromList(List.filled(16, 255)),
    );
  });

  test('contains all 2048 mnemonic translations', () {
    expect(englishToSimplifiedChinese.length, 2048);
    expect(translateMnemonic('abandon ability able about'), '放弃 能力 能够 关于');
    expect(
      () => translateMnemonic('abandon unknown-word'),
      throwsArgumentError,
    );
  });

  test('rejects unsupported entropy and coin flip sizes', () async {
    expect(() => service.derive(Uint8List(8)), throwsArgumentError);
    expect(
      () => service.entropyFromCoinFlips(List.filled(64, true)),
      throwsArgumentError,
    );
  });

  test('secure entropy source returns only supported lengths', () {
    final source = SecureEntropySource();
    expect(source.generate(128).length, 16);
    expect(source.generate(256).length, 32);
    expect(() => source.generate(64), throwsArgumentError);
  });
}
