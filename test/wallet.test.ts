import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  BITCOIN_PATH,
  ETHEREUM_PATH,
  SOLANA_PATH,
  deriveWalletFromEntropy,
} from "../src/wallet.js";

const ZERO_ENTROPY = `0x${"00".repeat(32)}`;

describe("deriveWalletFromEntropy", () => {
  it("derives a 24-word BIP-39 mnemonic from 256-bit entropy", () => {
    const wallet = deriveWalletFromEntropy(ZERO_ENTROPY);

    assert.equal(wallet.mnemonic, `${"abandon ".repeat(23)}art`);
    assert.equal(wallet.mnemonic.split(" ").length, 24);
  });

  it("derives deterministic addresses using the configured paths", () => {
    const wallet = deriveWalletFromEntropy(ZERO_ENTROPY);

    assert.equal(wallet.bitcoin.network, "mainnet");
    assert.equal(wallet.bitcoin.path, BITCOIN_PATH);
    assert.equal(wallet.ethereum.path, ETHEREUM_PATH);
    assert.equal(wallet.solana.path, SOLANA_PATH);
    assert.equal(
      wallet.bitcoin.address,
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
