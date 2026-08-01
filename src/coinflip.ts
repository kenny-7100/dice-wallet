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

  try {
    while (bits.length < FLIP_COUNT) {
      const answer = (
        await readline.question(
          `Flip ${bits.length + 1}/${FLIP_COUNT} (1 = heads, 2 = tails): `,
        )
      ).trim();

      if (answer === "1") {
        bits.push("0");
      } else if (answer === "2") {
        bits.push("1");
      } else {
        console.log("Invalid input. Please enter 1 or 2.");
      }
    }
  } finally {
    readline.close();
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
