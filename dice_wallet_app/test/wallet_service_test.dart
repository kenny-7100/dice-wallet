import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bs58/bs58.dart';
import 'package:crypto/crypto.dart';
import 'package:dice_wallet_app/core/mnemonic_translations.dart';
import 'package:dice_wallet_app/core/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('matches official BIP-39 boundary and non-zero entropy vectors', () async {
    final vectors = <(Uint8List, String)>[
      (
        Uint8List.fromList(List<int>.generate(16, (index) => index)),
        'abandon amount liar amount expire adjust cage candy arch gather drum buyer',
      ),
      (Uint8List.fromList(List<int>.filled(16, 0xff)), '${'zoo ' * 11}wrong'),
      (
        Uint8List.fromList(List<int>.generate(32, (index) => index)),
        'abandon amount liar amount expire adjust cage candy arch gather drum '
            'bullet absurd math era live bid rhythm alien crouch range attend '
            'journey unaware',
      ),
      (Uint8List.fromList(List<int>.filled(32, 0xff)), '${'zoo ' * 23}vote'),
    ];

    for (final (entropy, expectedMnemonic) in vectors) {
      final wallet = await service.derive(entropy);

      expect(wallet.mnemonic, expectedMnemonic);
      expect(bip39.validateMnemonic(wallet.mnemonic), isTrue);
      expect(bip39.mnemonicToEntropy(wallet.mnemonic), _hex(entropy));
      expect(
        wallet.mnemonic.split(' '),
        hasLength(entropy.length == 16 ? 12 : 24),
      );
    }
  });

  test(
    'returns every configured mainnet address with its exact path',
    () async {
      final wallet = await service.derive(
        Uint8List.fromList(List<int>.generate(32, (index) => index)),
      );

      expect(wallet.addresses.map((item) => (item.name, item.path)), [
        ('Bitcoin Native SegWit', bitcoinNativeSegwitPath),
        ('Bitcoin Taproot', bitcoinTaprootPath),
        ('Ethereum', ethereumPath),
        ('Solana', solanaPath),
        ('TRON', tronPath),
      ]);
      expect(
        wallet.addresses.map((item) => item.address).toSet(),
        hasLength(5),
      );
      expect(
        wallet.addresses[0].address,
        matches(RegExp(r'^bc1q[ac-hj-np-z02-9]{38}$')),
      );
      expect(
        wallet.addresses[1].address,
        matches(RegExp(r'^bc1p[ac-hj-np-z02-9]{58}$')),
      );
      expect(
        wallet.addresses[2].address,
        matches(RegExp(r'^0x[0-9A-Fa-f]{40}$')),
      );
      expect(
        wallet.addresses[3].address,
        matches(RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$')),
      );
      expect(
        wallet.addresses[4].address,
        matches(RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$')),
      );
      _expectValidTronBase58Check(wallet.addresses[4].address);
    },
  );

  test('coin flip mapping matches the CLI', () {
    expect(service.entropyFromCoinFlips(List.filled(128, true)), Uint8List(16));
    expect(
      service.entropyFromCoinFlips(List.filled(128, false)),
      Uint8List.fromList(List.filled(16, 255)),
    );

    expect(
      service.entropyFromCoinFlips(
        List<bool>.generate(128, (index) => index.isEven),
      ),
      Uint8List.fromList(List<int>.filled(16, 0x55)),
    );
    expect(
      service.entropyFromCoinFlips(
        List<bool>.generate(256, (index) => index.isOdd),
      ),
      Uint8List.fromList(List<int>.filled(32, 0xaa)),
    );

    final firstBit = List<bool>.filled(128, true)..first = false;
    final lastBit = List<bool>.filled(128, true)..last = false;
    expect(
      service.entropyFromCoinFlips(firstBit),
      Uint8List.fromList(<int>[0x80, ...List<int>.filled(15, 0)]),
    );
    expect(
      service.entropyFromCoinFlips(lastBit),
      Uint8List.fromList(<int>[...List<int>.filled(15, 0), 0x01]),
    );
  });

  test('contains 2048 mnemonic meanings for every language', () async {
    const languages = [
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
    for (final language in languages) {
      final translations = await MnemonicTranslations.load(language);
      expect(translations.length, 2048, reason: language);
      expect(translations.values.every((value) => value.isNotEmpty), isTrue);
    }
    final chinese = await MnemonicTranslations.load('zh');
    expect(chinese['abandon'], '放弃');
    expect(chinese['about'], '关于');
  });

  test('rejects every unsupported entropy and coin flip boundary', () async {
    for (final length in [0, 8, 15, 17, 31, 33]) {
      expect(
        () => service.derive(Uint8List(length)),
        throwsArgumentError,
        reason: 'entropy length: $length',
      );
    }
    for (final length in [0, 64, 127, 129, 255, 257]) {
      expect(
        () => service.entropyFromCoinFlips(List<bool>.filled(length, true)),
        throwsArgumentError,
        reason: 'coin flip length: $length',
      );
    }
  });

  test('secure entropy source returns independent supported byte arrays', () {
    final source = SecureEntropySource();
    final first128 = source.generate(128);
    final second128 = source.generate(128);
    final entropy256 = source.generate(256);

    expect(first128, hasLength(16));
    expect(second128, hasLength(16));
    expect(entropy256, hasLength(32));
    expect(identical(first128, second128), isFalse);
    expect(first128, isNot(equals(second128)));

    final secondSnapshot = Uint8List.fromList(second128);
    first128.fillRange(0, first128.length, 0);
    expect(second128, secondSnapshot);

    for (final bitLength in [0, 64, 127, 129, 192, 255, 257, 512]) {
      expect(
        () => source.generate(bitLength),
        throwsArgumentError,
        reason: 'bit length: $bitLength',
      );
    }
  });
}

String _hex(Iterable<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void _expectValidTronBase58Check(String address) {
  final decoded = base58.decode(address);
  final payload = decoded.sublist(0, decoded.length - 4);
  final checksum = decoded.sublist(decoded.length - 4);
  final expectedChecksum = sha256
      .convert(sha256.convert(payload).bytes)
      .bytes
      .take(4);

  expect(decoded, hasLength(25));
  expect(payload.first, 0x41);
  expect(checksum, expectedChecksum);
}
