import { createHash } from "node:crypto";

import BIP32Factory from "bip32";
import * as bip39 from "bip39";
import { initEccLib, networks, payments } from "bitcoinjs-lib";
import bs58 from "bs58";
import { derivePath } from "ed25519-hd-key";
import { HDNodeWallet } from "ethers";
import * as ecc from "tiny-secp256k1";
import nacl from "tweetnacl";

export const BITCOIN_NATIVE_SEGWIT_PATH = "m/84'/0'/0'/0/0" as const;
export const BITCOIN_TAPROOT_PATH = "m/86'/0'/0'/0/0" as const;
export const ETHEREUM_PATH = "m/44'/60'/0'/0/0" as const;
export const SOLANA_PATH = "m/44'/501'/0'/0'" as const;
export const TRON_PATH = "m/44'/195'/0'/0/0" as const;

const ENTROPY_128_PATTERN = /^0x[0-9a-fA-F]{32}$/;
const ENTROPY_256_PATTERN = /^0x[0-9a-fA-F]{64}$/;
const bip32 = BIP32Factory(ecc);
initEccLib(ecc);

export interface DerivedWallet {
  mnemonic: string;
  bitcoin: {
    network: "mainnet";
    nativeSegwit: {
      path: typeof BITCOIN_NATIVE_SEGWIT_PATH;
      address: string;
    };
    taproot: {
      path: typeof BITCOIN_TAPROOT_PATH;
      address: string;
    };
  };
  ethereum: {
    path: typeof ETHEREUM_PATH;
    address: string;
  };
  solana: {
    path: typeof SOLANA_PATH;
    address: string;
  };
  tron: {
    path: typeof TRON_PATH;
    address: string;
  };
}

/** Derives public addresses from exactly 256 bits of BIP-39 entropy. */
export function deriveWalletFromEntropy(entropyHex: string): DerivedWallet {
  if (!ENTROPY_256_PATTERN.test(entropyHex)) {
    throw new TypeError(
      "entropyHex must start with 0x and contain exactly 64 hexadecimal characters",
    );
  }

  const mnemonic = bip39.entropyToMnemonic(entropyHex.slice(2).toLowerCase());
  return deriveWalletFromMnemonic(mnemonic);
}

/** Derives public addresses from exactly 128 bits of BIP-39 entropy. */
export function deriveWalletFrom128BitEntropy(entropyHex: string): DerivedWallet {
  if (!ENTROPY_128_PATTERN.test(entropyHex)) {
    throw new TypeError(
      "entropyHex must start with 0x and contain exactly 32 hexadecimal characters",
    );
  }

  const mnemonic = bip39.entropyToMnemonic(entropyHex.slice(2).toLowerCase());
  return deriveWalletFromMnemonic(mnemonic);
}

function deriveWalletFromMnemonic(mnemonic: string): DerivedWallet {
  const seed = bip39.mnemonicToSeedSync(mnemonic);

  const bitcoinRoot = bip32.fromSeed(seed, networks.bitcoin);
  const nativeSegwitNode = bitcoinRoot.derivePath(BITCOIN_NATIVE_SEGWIT_PATH);
  const nativeSegwitAddress = payments.p2wpkh({
    pubkey: nativeSegwitNode.publicKey,
    network: networks.bitcoin,
  }).address;

  const taprootNode = bitcoinRoot.derivePath(BITCOIN_TAPROOT_PATH);
  const internalPubkey = taprootNode.publicKey.subarray(1, 33);
  const taprootAddress = payments.p2tr({
    internalPubkey,
    network: networks.bitcoin,
  }).address;

  if (!nativeSegwitAddress || !taprootAddress) {
    throw new Error("failed to derive Bitcoin addresses");
  }

  const ethereumAddress = HDNodeWallet.fromPhrase(
    mnemonic,
    undefined,
    ETHEREUM_PATH,
  ).address;

  const solanaSeed = derivePath(SOLANA_PATH, seed.toString("hex")).key;
  const solanaPublicKey = nacl.sign.keyPair.fromSeed(solanaSeed).publicKey;

  const tronHexAddress = HDNodeWallet.fromPhrase(
    mnemonic,
    undefined,
    TRON_PATH,
  ).address;
  const tronPayload = Buffer.from(`41${tronHexAddress.slice(2)}`, "hex");
  const firstHash = createHash("sha256").update(tronPayload).digest();
  const checksum = createHash("sha256").update(firstHash).digest().subarray(0, 4);

  return {
    mnemonic,
    bitcoin: {
      network: "mainnet",
      nativeSegwit: {
        path: BITCOIN_NATIVE_SEGWIT_PATH,
        address: nativeSegwitAddress,
      },
      taproot: {
        path: BITCOIN_TAPROOT_PATH,
        address: taprootAddress,
      },
    },
    ethereum: {
      path: ETHEREUM_PATH,
      address: ethereumAddress,
    },
    solana: {
      path: SOLANA_PATH,
      address: bs58.encode(solanaPublicKey),
    },
    tron: {
      path: TRON_PATH,
      address: bs58.encode(Buffer.concat([tronPayload, checksum])),
    },
  };
}
