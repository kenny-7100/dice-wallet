import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const sourceRoot = resolve(root, '..', 'src');
const locales = {
  zh: 'zh-CN', es: 'es', hi: 'hi', pt: 'pt', ru: 'ru', ja: 'ja', ko: 'ko',
  de: 'de', fr: 'fr', tr: 'tr', vi: 'vi', id: 'id', ar: 'ar', fa: 'fa',
  uk: 'uk', th: 'th', fil: 'fil', it: 'it', nl: 'nl',
};

const uiEnglish = {
  appName: 'Dice Wallet', createWallet: 'Create your wallet offline',
  homeDescription: 'Choose an entropy source and mnemonic length. Generation, derivation, and display happen only in memory on this device.',
  secureRandom: 'Secure system randomness', manualCoinFlip: 'Manual coin flips', randomGenerate: 'Random',
  wordCount: '{count} words', secureEntropyBits: '{count}-bit secure entropy', coinFlip: 'Coin flip',
  recordResults: 'Record {count} results', privacyNote: 'No network, storage, or upload. Wallet data is released when you leave the result screen.',
  language: 'Language', systemDefault: 'System default', languageDescription: 'The app follows your device unless you choose a language.',
  randomTitle: 'Secure system randomness', generateWallet: 'Generate a {count}-word wallet',
  randomDescription: 'Entropy comes from the operating system cryptographically secure random source. Wallet derivation happens in memory and is never written to files, preferences, or a database.',
  entropyStrength: 'Entropy strength', bits: '{count} bits', mnemonic: 'Mnemonic', words: '{count} words', storage: 'Storage', memoryOnly: 'Memory only',
  derivingAddresses: 'Deriving addresses', generateSecurely: 'Generate securely',
  discardTitle: 'Discard this record?', discardMessage: 'You have recorded {count} results. They cannot be recovered after leaving.',
  continueRecording: 'Continue', discard: 'Discard', coinFlipTitle: '{count} coin flips', undoLast: 'Undo last result',
  prepareCoin: 'Prepare a regular coin', coinIntro: 'Flip the physical coin each time, then tap the result. Stay focused and do not skip or invent results.',
  coinMapping: 'Heads is 0 and tails is 1. Record {count} consecutive results; you can undo the latest result at any time.',
  startRecording: 'Start recording', recordComplete: 'Recording complete', flipNumber: 'Flip {count}', derivingWallet: 'Deriving wallet addresses...',
  chooseFace: 'After flipping, choose the face that landed upward', heads: 'Heads', tails: 'Tails', recordedAs: 'Record as {bit}', remaining: '{count} remaining', recentResults: 'Recent results',
  walletGenerated: 'Wallet generated', showMnemonic: 'Show mnemonic and word meanings', hideInBackground: 'Automatically hides when the app leaves the foreground',
  publicAddresses: 'Public addresses', publicAddressHelp: 'These addresses are safe to share. Copying never includes the mnemonic.',
  clearAndHome: 'Clear and return home', derivationComplete: 'Derivation complete', backupReminder: 'Nothing has been saved. Complete an offline backup now.',
  sensitiveHidden: 'Sensitive content hidden', secretWarning: 'Anyone with these words can control the wallet. Do not screenshot, copy, or send them.',
  addressCopied: '{name} address copied', copyAddress: 'Copy address',
};

function restorePlaceholders(source, translated) {
  const expected = [...source.matchAll(/\{\w+\}/g)].map((match) => match[0]);
  let index = 0;
  const restored = translated.replace(/\{[^}]+\}/gu, () => expected[index++] ?? '');
  if (index !== expected.length) {
    throw new Error(`Placeholder mismatch: ${source} -> ${translated}`);
  }
  return restored;
}

async function translateLines(lines, target) {
  const translated = [];
  for (let start = 0; start < lines.length; start += 80) {
    const batch = lines.slice(start, start + 80);
    const params = new URLSearchParams({ client: 'gtx', sl: 'en', tl: target, dt: 't', q: batch.join('\n') });
    let response;
    for (let attempt = 0; attempt < 4; attempt++) {
      response = await fetch(`https://translate.googleapis.com/translate_a/single?${params}`);
      if (response.ok) break;
      await new Promise((resolve) => setTimeout(resolve, 500 * (attempt + 1)));
    }
    if (!response?.ok) throw new Error(`Translation failed for ${target}: ${response?.status}`);
    const data = await response.json();
    const text = data[0].map((part) => part[0]).join('');
    const output = text.split('\n');
    if (output.length !== batch.length) throw new Error(`Line mismatch for ${target}: ${output.length}/${batch.length}`);
    translated.push(...output.map((value) => value.trim()));
  }
  return translated;
}

async function main() {
  await mkdir(resolve(root, 'assets/i18n'), { recursive: true });
  await mkdir(resolve(root, 'assets/mnemonic'), { recursive: true });
  await writeFile(resolve(root, 'assets/i18n/en.json'), `${JSON.stringify(uiEnglish, null, 2)}\n`);

  const source = await readFile(resolve(sourceRoot, 'mnemonic-translations.ts'), 'utf8');
  const pairs = [...source.matchAll(/^  "([a-z]+)": "([^"]+)",$/gm)].map((match) => [match[1], match[2]]);
  if (pairs.length !== 2048) throw new Error(`Expected 2048 mnemonic words, got ${pairs.length}`);
  const words = pairs.map(([word]) => word);
  await writeFile(resolve(root, 'assets/mnemonic/en.json'), `${JSON.stringify(Object.fromEntries(words.map((word) => [word, word])), null, 2)}\n`);
  await writeFile(resolve(root, 'assets/mnemonic/zh.json'), `${JSON.stringify(Object.fromEntries(pairs), null, 2)}\n`);

  const uiValues = Object.values(uiEnglish);
  const uiKeys = Object.keys(uiEnglish);
  for (const [locale, target] of Object.entries(locales)) {
    // Simplified Chinese UI copy is curated directly in assets/i18n/zh.json.
    if (locale === 'zh') {
      process.stdout.write('kept curated zh UI and mnemonic meanings\n');
      continue;
    }
    const translatedUi = (await translateLines(uiValues, target)).map(
      (value, index) => restorePlaceholders(uiValues[index], value),
    );
    await writeFile(resolve(root, `assets/i18n/${locale}.json`), `${JSON.stringify(Object.fromEntries(uiKeys.map((key, index) => [key, translatedUi[index]])), null, 2)}\n`);
    const meanings = await translateLines(words, target);
    await writeFile(resolve(root, `assets/mnemonic/${locale}.json`), `${JSON.stringify(Object.fromEntries(words.map((word, index) => [word, meanings[index]])), null, 2)}\n`);
    process.stdout.write(`generated ${locale}\n`);
  }
}

await main();
