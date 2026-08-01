import 'package:flutter/material.dart';

import '../core/wallet_service.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('系统安全随机数')),
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
                '生成 ${widget.bitLength == 128 ? 12 : 24} 词钱包',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '熵由操作系统提供的加密安全随机源生成。钱包派生在内存中完成，不会写入本地文件、偏好设置或数据库。',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.55, color: Color(0xFF59635E)),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _Fact(label: '熵强度', value: '${widget.bitLength} 位'),
                      const Divider(height: 24),
                      _Fact(
                        label: '助记词',
                        value: '${widget.bitLength == 128 ? 12 : 24} 个单词',
                      ),
                      const Divider(height: 24),
                      const _Fact(label: '存储', value: '仅内存'),
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
                  label: Text(_working ? '正在派生地址' : '安全生成'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Color(0xFF68716D))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
