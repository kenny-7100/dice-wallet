import { randomBytes } from "node:crypto";

import { translateMnemonic } from "./mnemonic-translations.js";
import { deriveWalletFromEntropy } from "./wallet.js";

const entropyHex = `0x${randomBytes(32).toString("hex")}`;
const wallet = deriveWalletFromEntropy(entropyHex);
const indent = "     ";

console.log(`🔑 Mnemonic:\n${indent}${wallet.mnemonic}\n`);
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
