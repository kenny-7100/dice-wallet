import 'package:flutter/material.dart';

import '../core/wallet_service.dart';
import '../l10n/app_strings.dart';
import 'wallet_result_screen.dart';

class RandomWalletScreen extends StatefulWidget {
  const RandomWalletScreen({super.key, required this.bitLength});
  final int bitLength;

  @override
  State<RandomWalletScreen> createState() => _RandomWalletScreenState();
}

class _RandomWalletScreenState extends State<RandomWalletScreen> {
  bool _working = false;

  Future<void> _generate() async {
    setState(() => _working = true);
    final entropy = SecureEntropySource().generate(widget.bitLength);
    try {
      final wallet = await WalletService().derive(entropy);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WalletResultScreen(wallet: wallet)),
      );
    } finally {
      entropy.fillRange(0, entropy.length, 0);
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wordCount = widget.bitLength == 128 ? 12 : 24;
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('randomTitle'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EFE9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 38,
                    color: Color(0xFF176B4D),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  strings.text('generateWallet', {'count': wordCount}),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.text('randomDescription'),
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.55, color: Color(0xFF59635E)),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _Fact(
                          label: strings.text('entropyStrength'),
                          value: strings.text('bits', {
                            'count': widget.bitLength,
                          }),
                        ),
                        const Divider(height: 24),
                        _Fact(
                          label: strings.text('mnemonic'),
                          value: strings.text('words', {'count': wordCount}),
                        ),
                        const Divider(height: 24),
                        _Fact(
                          label: strings.text('storage'),
                          value: strings.text('memoryOnly'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _working ? null : _generate,
                    icon: _working
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.casino_outlined),
                    label: Text(
                      strings.text(
                        _working ? 'derivingAddresses' : 'generateSecurely',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: Color(0xFF68716D))),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
