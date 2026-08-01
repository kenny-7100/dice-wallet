import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { translateMnemonic } from "../src/mnemonic-translations.js";
import {
  BITCOIN_NATIVE_SEGWIT_PATH,
  BITCOIN_TAPROOT_PATH,
  ETHEREUM_PATH,
  SOLANA_PATH,
  TRON_PATH,
  deriveWalletFrom128BitEntropy,
  deriveWalletFromEntropy,
} from "../src/wallet.js";

const ZERO_ENTROPY = `0x${"00".repeat(32)}`;
const ZERO_128_BIT_ENTROPY = `0x${"00".repeat(16)}`;

describe("translateMnemonic", () => {
  it("translates every mnemonic word while preserving its order", () => {
    assert.equal(
      translateMnemonic("abandon ability able about"),
      "放弃 能力 能够 关于",
    );
  });

  it("rejects words outside the English BIP-39 word list", () => {
    assert.throws(() => translateMnemonic("abandon unknown"), {
      message: "missing mnemonic translation for: unknown",
    });
  });
});

describe("deriveWalletFromEntropy", () => {
  it("derives a 24-word BIP-39 mnemonic from 256-bit entropy", () => {
    const wallet = deriveWalletFromEntropy(ZERO_ENTROPY);

    assert.equal(wallet.mnemonic, `${"abandon ".repeat(23)}art`);
    assert.equal(wallet.mnemonic.split(" ").length, 24);
  });

  it("derives deterministic addresses using the configured paths", () => {
    const wallet = deriveWalletFromEntropy(ZERO_ENTROPY);

    assert.equal(wallet.bitcoin.network, "mainnet");
    assert.equal(wallet.bitcoin.nativeSegwit.path, BITCOIN_NATIVE_SEGWIT_PATH);
    assert.equal(wallet.bitcoin.taproot.path, BITCOIN_TAPROOT_PATH);
    assert.equal(wallet.ethereum.path, ETHEREUM_PATH);
    assert.equal(wallet.solana.path, SOLANA_PATH);
    assert.equal(wallet.tron.path, TRON_PATH);
    assert.equal(
      wallet.bitcoin.nativeSegwit.address,
      "bc1qzmtrqsfuaf6l6kkcsseumq26ukaphfj9skkug6",
    );
    assert.equal(
      wallet.bitcoin.taproot.address,
      "bc1p68a8a3vuv2cxzs7e2gjc5v3qy3zdnfaxwftyqe9k9nquvm6r4w2ssldtzp",
    );
    assert.equal(
      wallet.ethereum.address,
      "0xF278cF59F82eDcf871d630F28EcC8056f25C1cdb",
    );
    assert.equal(
      wallet.solana.address,
      "3Cy3YNTFywCmxoxt8n7UH6hg6dLo5uACowX3CFceaSnx",
    );
    assert.match(wallet.tron.address, /^T[1-9A-HJ-NP-Za-km-z]{33}$/);
  });

  it("treats hexadecimal input case-insensitively", () => {
    const mixedCaseEntropy = `0x${"aB".repeat(32)}`;

    assert.deepEqual(
      deriveWalletFromEntropy(mixedCaseEntropy),
      deriveWalletFromEntropy(mixedCaseEntropy.toLowerCase()),
    );
  });

  it("rejects values that are not exactly 256-bit prefixed hex", () => {
    const invalidValues = [
      "",
      "00".repeat(32),
      `0x${"00".repeat(31)}`,
      `0x${"00".repeat(33)}`,
      `0x${"gg".repeat(32)}`,
    ];

    for (const value of invalidValues) {
      assert.throws(() => deriveWalletFromEntropy(value), {
        name: "TypeError",
        message:
          "entropyHex must start with 0x and contain exactly 64 hexadecimal characters",
      });
    }
  });
});

describe("deriveWalletFrom128BitEntropy", () => {
  it("derives a 12-word BIP-39 mnemonic and all configured addresses", () => {
    const wallet = deriveWalletFrom128BitEntropy(ZERO_128_BIT_ENTROPY);

    assert.equal(wallet.mnemonic, `${"abandon ".repeat(11)}about`);
    assert.equal(wallet.mnemonic.split(" ").length, 12);
    assert.match(wallet.bitcoin.nativeSegwit.address, /^bc1q[ac-hj-np-z02-9]{38}$/);
    assert.match(wallet.bitcoin.taproot.address, /^bc1p[ac-hj-np-z02-9]{58}$/);
    assert.match(wallet.ethereum.address, /^0x[0-9A-Fa-f]{40}$/);
    assert.match(wallet.solana.address, /^[1-9A-HJ-NP-Za-km-z]{32,44}$/);
    assert.match(wallet.tron.address, /^T[1-9A-HJ-NP-Za-km-z]{33}$/);
  });

  it("rejects values that are not exactly 128-bit prefixed hex", () => {
    const invalidValues = [
      "",
      "00".repeat(16),
      `0x${"00".repeat(15)}`,
      `0x${"00".repeat(17)}`,
      `0x${"gg".repeat(16)}`,
    ];

    for (const value of invalidValues) {
      assert.throws(() => deriveWalletFrom128BitEntropy(value), {
        name: "TypeError",
        message:
          "entropyHex must start with 0x and contain exactly 32 hexadecimal characters",
      });
    }
  });
});
