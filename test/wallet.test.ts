import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { describe, it } from "node:test";

import * as bip39 from "bip39";
import bs58 from "bs58";

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

function assertValidTronBase58Check(address: string): void {
  const decoded = Buffer.from(bs58.decode(address));
  const payload = decoded.subarray(0, -4);
  const checksum = decoded.subarray(-4);
  const firstHash = createHash("sha256").update(payload).digest();
  const expectedChecksum = createHash("sha256")
    .update(firstHash)
    .digest()
    .subarray(0, 4);

  assert.equal(decoded.length, 25);
  assert.equal(payload[0], 0x41);
  assert.deepEqual(checksum, expectedChecksum);
}

function runEntryPoint(file: string): string {
  const result = spawnSync(
    process.execPath,
    ["--import", "tsx", file],
    { cwd: process.cwd(), encoding: "utf8" },
  );

  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stderr, "");
  return result.stdout;
}

describe("translateMnemonic", () => {
  it("translates every mnemonic word while preserving its order", () => {
    assert.equal(
      translateMnemonic("abandon ability able about"),
      "放弃 能力 能够 关于",
    );
  });

  it("rejects words outside the English BIP-39 word list", () => {
    assert.throws(() => translateMnemonic("abandon not-a-bip39-word"), {
      message: "missing mnemonic translation for: not-a-bip39-word",
    });
  });

  it("contains a translation for every English BIP-39 word", () => {
    const translatedWords = translateMnemonic(
      bip39.wordlists.english.join(" "),
    ).split(" ");

    assert.equal(bip39.wordlists.english.length, 2048);
    assert.equal(translatedWords.length, bip39.wordlists.english.length);
    assert.ok(translatedWords.every((word) => word.length > 0));
  });

  it("preserves repeated words", () => {
    assert.equal(
      translateMnemonic("abandon abandon ability"),
      "放弃 放弃 能力",
    );
  });

  it("rejects empty words caused by unsupported whitespace", () => {
    for (const mnemonic of ["", " abandon", "abandon ", "abandon  ability"]) {
      assert.throws(() => translateMnemonic(mnemonic), {
        message: "missing mnemonic translation for: ",
      });
    }
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
    assert.equal(wallet.tron.address, "TEfhiqsW1SdN44DeHrAWVmbyr8ZbvChrtS");
    assertValidTronBase58Check(wallet.tron.address);
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
      `0X${"00".repeat(32)}`,
      ` 0x${"00".repeat(32)}`,
      `0x${"00".repeat(32)} `,
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
    assert.equal(
      wallet.bitcoin.nativeSegwit.address,
      "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu",
    );
    assert.equal(
      wallet.bitcoin.taproot.address,
      "bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr",
    );
    assert.equal(wallet.ethereum.address, "0x9858EfFD232B4033E47d90003D41EC34EcaEda94");
    assert.equal(wallet.solana.address, "HAgk14JpMQLgt6rVgv7cBQFJWFto5Dqxi472uT3DKpqk");
    assert.equal(wallet.tron.address, "TUEZSdKsoDHQMeZwihtdoBiN46zxhGWYdH");
    assertValidTronBase58Check(wallet.tron.address);
  });

  it("rejects values that are not exactly 128-bit prefixed hex", () => {
    const invalidValues = [
      "",
      "00".repeat(16),
      `0x${"00".repeat(15)}`,
      `0x${"00".repeat(17)}`,
      `0x${"gg".repeat(16)}`,
      `0X${"00".repeat(16)}`,
      ` 0x${"00".repeat(16)}`,
      `0x${"00".repeat(16)} `,
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

describe("command entry points", () => {
  for (const [file, wordCount] of [
    ["src/random.ts", 24],
    ["src/random12.ts", 12],
  ] as const) {
    it(`generates and prints a ${wordCount}-word wallet from ${file}`, () => {
      const output = runEntryPoint(file);
      const mnemonic = output.match(/Mnemonic:\n     ([a-z ]+)\n/)?.[1];
      const translation = output.match(/Mnemonic Translation:\n     (.+)\n/)?.[1];

      assert.ok(mnemonic);
      assert.ok(bip39.validateMnemonic(mnemonic));
      assert.equal(mnemonic.split(" ").length, wordCount);
      assert.equal(translation, translateMnemonic(mnemonic));
      assert.match(output, /Bitcoin Native SegWit address:\n     bc1q[ac-hj-np-z02-9]{38}\n/);
      assert.match(output, /Bitcoin Taproot address:\n     bc1p[ac-hj-np-z02-9]{58} /);
      assert.match(output, /Ethereum address:\n     0x[0-9A-Fa-f]{40}\n/);
      assert.match(output, /Solana address:\n     [1-9A-HJ-NP-Za-km-z]{32,44}\n/);

      const tronAddress = output.match(
        /TRON address:\n     (T[1-9A-HJ-NP-Za-km-z]{33})\n/,
      )?.[1];
      assert.ok(tronAddress);
      assertValidTronBase58Check(tronAddress);
    });
  }
});
