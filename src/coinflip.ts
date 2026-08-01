import { createInterface } from "node:readline/promises";
import { stdin, stdout } from "node:process";

import { translateMnemonic } from "./mnemonic-translations.js";
import { deriveWalletFromEntropy } from "./wallet.js";

const FLIP_COUNT = 256;
const indent = "     ";

async function main(): Promise<void> {
  const readline = createInterface({ input: stdin, output: stdout });
  const bits: string[] = [];

  console.log("Flip a coin 256 times. Enter 1 for heads or 2 for tails.\n");
  stdout.write(`Flip 1/${FLIP_COUNT} (1 = heads, 2 = tails): `);

  try {
    for await (const line of readline) {
      const answer = line.trim();

      if (answer === "1") {
        bits.push("0");
      } else if (answer === "2") {
        bits.push("1");
      } else {
        console.log("Invalid input. Please enter 1 or 2.");
      }

      if (bits.length === FLIP_COUNT) {
        break;
      }

      stdout.write(
        `Flip ${bits.length + 1}/${FLIP_COUNT} (1 = heads, 2 = tails): `,
      );
    }
  } finally {
    readline.close();
  }

  if (bits.length !== FLIP_COUNT) {
    throw new Error(`input ended after ${bits.length} of ${FLIP_COUNT} flips`);
  }

  const entropy = Buffer.from(
    Array.from({ length: FLIP_COUNT / 8 }, (_, index) =>
      Number.parseInt(bits.slice(index * 8, index * 8 + 8).join(""), 2),
    ),
  );
  const entropyHex = `0x${entropy.toString("hex")}`;
  const wallet = deriveWalletFromEntropy(entropyHex);

  console.log(`\n🔑 Mnemonic:\n${indent}${wallet.mnemonic}\n`);
  console.log(
    `🔑 Mnemonic Translation:\n${indent}${translateMnemonic(wallet.mnemonic)}\n`,
  );
  console.log(
    `🟢 Bitcoin Native SegWit address:\n${indent}${wallet.bitcoin.nativeSegwit.address}\n`,
  );
  console.log(
    `🟠 Bitcoin Taproot address:\n${indent}${wallet.bitcoin.taproot.address} (Not recommended for quantum resistance)\n`,
  );
  console.log(`💎 Ethereum address:\n${indent}${wallet.ethereum.address}\n`);
  console.log(`🚀 Solana address:\n${indent}${wallet.solana.address}\n`);
  console.log(`🚚 TRON address:\n${indent}${wallet.tron.address}\n`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
