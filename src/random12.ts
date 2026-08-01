import { randomBytes } from "node:crypto";

import { deriveWalletFrom128BitEntropy } from "./wallet.js";

const entropyHex = `0x${randomBytes(16).toString("hex")}`;
const wallet = deriveWalletFrom128BitEntropy(entropyHex);

console.log("Mnemonic:", wallet.mnemonic);
console.log("Bitcoin Taproot address:", wallet.bitcoin.address);
console.log("Ethereum address:", wallet.ethereum.address);
console.log("Solana address:", wallet.solana.address);
