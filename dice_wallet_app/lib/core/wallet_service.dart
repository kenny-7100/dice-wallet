import 'dart:math';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bs58/bs58.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:pointycastle/digests/keccak.dart';

const bitcoinNativeSegwitPath = "m/84'/0'/0'/0/0";
const bitcoinTaprootPath = "m/86'/0'/0'/0/0";
const ethereumPath = "m/44'/60'/0'/0/0";
const solanaPath = "m/44'/501'/0'/0'";
const tronPath = "m/44'/195'/0'/0/0";

class WalletAddress {
  const WalletAddress(this.name, this.path, this.address);

  final String name;
  final String path;
  final String address;
}

class DerivedWallet {
  const DerivedWallet({required this.mnemonic, required this.addresses});

  final String mnemonic;
  final List<WalletAddress> addresses;
}

class SecureEntropySource {
  SecureEntropySource() : _random = Random.secure();

  final Random _random;

  Uint8List generate(int bitLength) {
    if (bitLength != 128 && bitLength != 256) {
      throw ArgumentError.value(bitLength, 'bitLength', 'must be 128 or 256');
    }
    return Uint8List.fromList(
      List<int>.generate(bitLength ~/ 8, (_) => _random.nextInt(256)),
    );
  }
}

class WalletService {
  Future<DerivedWallet> derive(Uint8List entropy) async {
    if (entropy.length != 16 && entropy.length != 32) {
      throw ArgumentError.value(
        entropy.length,
        'entropy',
        'must be 16 or 32 bytes',
      );
    }

    final mnemonic = bip39.entropyToMnemonic(_hex(entropy));
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);

    final segwitPublic = root.derivePath(bitcoinNativeSegwitPath).publicKey;
    final taprootPublic = root.derivePath(bitcoinTaprootPath).publicKey;
    final ethereumPublic = _publicKey(
      root.derivePath(ethereumPath).privateKey!,
    );
    final tronPublic = _publicKey(root.derivePath(tronPath).privateKey!);
    final solanaKey = await ED25519_HD_KEY.derivePath(solanaPath, seed);
    final solanaPublic = SigningKey.fromSeed(
      Uint8List.fromList(solanaKey.key),
    ).verifyKey.asTypedList;

    final ethereumBytes = _keccak(ethereumPublic.sublist(1)).sublist(12);
    final ethereumLower = _hex(ethereumBytes);
    final tronPayload = <int>[
      0x41,
      ..._keccak(tronPublic.sublist(1)).sublist(12),
    ];
    final tronChecksum = sha256
        .convert(sha256.convert(tronPayload).bytes)
        .bytes;

    return DerivedWallet(
      mnemonic: mnemonic,
      addresses: [
        WalletAddress(
          'Bitcoin Native SegWit',
          bitcoinNativeSegwitPath,
          ECPublic.fromBytes(
            segwitPublic,
          ).toSegwitAddress().toAddress(BitcoinNetwork.mainnet),
        ),
        WalletAddress(
          'Bitcoin Taproot',
          bitcoinTaprootPath,
          ECPublic.fromBytes(
            taprootPublic,
          ).toTaprootAddress().toAddress(BitcoinNetwork.mainnet),
        ),
        WalletAddress(
          'Ethereum',
          ethereumPath,
          _checksumAddress(ethereumLower),
        ),
        WalletAddress('Solana', solanaPath, base58.encode(solanaPublic)),
        WalletAddress(
          'TRON',
          tronPath,
          base58.encode(
            Uint8List.fromList(<int>[...tronPayload, ...tronChecksum.take(4)]),
          ),
        ),
      ],
    );
  }

  Uint8List entropyFromCoinFlips(List<bool> flips) {
    if (flips.length != 128 && flips.length != 256) {
      throw ArgumentError.value(
        flips.length,
        'flips',
        'must contain 128 or 256 results',
      );
    }
    return Uint8List.fromList(
      List<int>.generate(flips.length ~/ 8, (byteIndex) {
        var value = 0;
        for (var bit = 0; bit < 8; bit++) {
          value = (value << 1) | (flips[byteIndex * 8 + bit] ? 0 : 1);
        }
        return value;
      }),
    );
  }

  Uint8List _publicKey(Uint8List privateKey) =>
      Uint8List.fromList(ECPrivate.fromBytes(privateKey).getPublic().toBytes());

  Uint8List _keccak(List<int> input) {
    final digest = KeccakDigest(256)
      ..update(Uint8List.fromList(input), 0, input.length);
    final output = Uint8List(digest.digestSize);
    digest.doFinal(output, 0);
    return output;
  }

  String _checksumAddress(String lowerAddress) {
    final hash = _hex(_keccak(Uint8List.fromList(lowerAddress.codeUnits)));
    final result = StringBuffer('0x');
    for (var i = 0; i < lowerAddress.length; i++) {
      final char = lowerAddress[i];
      result.write(
        int.parse(hash[i], radix: 16) >= 8 ? char.toUpperCase() : char,
      );
    }
    return result.toString();
  }

  String _hex(Iterable<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
