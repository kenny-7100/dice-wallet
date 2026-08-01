import { randomBytes } from "node:crypto";

import { deriveWalletFromEntropy } from "./wallet.js";

const entropyHex = `0x${randomBytes(32).toString("hex")}`;
const wallet = deriveWalletFromEntropy(entropyHex);

console.log("Mnemonic:", wallet.mnemonic);
console.log("Bitcoin Taproot address:", wallet.bitcoin.address);
console.log("Ethereum address:", wallet.ethereum.address);
console.log("Solana address:", wallet.solana.address);
