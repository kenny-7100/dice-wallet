import BIP32Factory from "bip32";
import * as bip39 from "bip39";
import { initEccLib, networks, payments } from "bitcoinjs-lib";
import bs58 from "bs58";
import { derivePath } from "ed25519-hd-key";
import { HDNodeWallet } from "ethers";
import * as ecc from "tiny-secp256k1";
import nacl from "tweetnacl";

export const BITCOIN_PATH = "m/86'/0'/0'/0/0" as const;
export const ETHEREUM_PATH = "m/44'/60'/0'/0/0" as const;
export const SOLANA_PATH = "m/44'/501'/0'/0'" as const;

const ENTROPY_PATTERN = /^0x[0-9a-fA-F]{64}$/;
const bip32 = BIP32Factory(ecc);
initEccLib(ecc);

export interface DerivedWallet {
  mnemonic: string;
  bitcoin: {
    network: "mainnet";
    path: typeof BITCOIN_PATH;
    address: string;
  };
  ethereum: {
    path: typeof ETHEREUM_PATH;
    address: string;
  };
  solana: {
    path: typeof SOLANA_PATH;
    address: string;
  };
}

/** Derives public addresses from exactly 256 bits of BIP-39 entropy. */
export function deriveWalletFromEntropy(entropyHex: string): DerivedWallet {
  if (!ENTROPY_PATTERN.test(entropyHex)) {
    throw new TypeError(
      "entropyHex must start with 0x and contain exactly 64 hexadecimal characters",
    );
  }

  const mnemonic = bip39.entropyToMnemonic(entropyHex.slice(2).toLowerCase());
  const seed = bip39.mnemonicToSeedSync(mnemonic);

  const bitcoinNode = bip32.fromSeed(seed, networks.bitcoin).derivePath(BITCOIN_PATH);
  const internalPubkey = bitcoinNode.publicKey.subarray(1, 33);
  const bitcoinAddress = payments.p2tr({
    internalPubkey,
    network: networks.bitcoin,
  }).address;

  if (!bitcoinAddress) {
    throw new Error("failed to derive Bitcoin Taproot address");
  }

  const ethereumAddress = HDNodeWallet.fromPhrase(
    mnemonic,
    undefined,
    ETHEREUM_PATH,
  ).address;

  const solanaSeed = derivePath(SOLANA_PATH, seed.toString("hex")).key;
  const solanaPublicKey = nacl.sign.keyPair.fromSeed(solanaSeed).publicKey;

  return {
    mnemonic,
    bitcoin: {
      network: "mainnet",
      path: BITCOIN_PATH,
      address: bitcoinAddress,
    },
    ethereum: {
      path: ETHEREUM_PATH,
      address: ethereumAddress,
    },
    solana: {
      path: SOLANA_PATH,
      address: bs58.encode(solanaPublicKey),
    },
  };
}
