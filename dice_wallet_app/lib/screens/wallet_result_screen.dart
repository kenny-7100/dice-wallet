import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/mnemonic_translations.dart';
import '../core/wallet_service.dart';

class WalletResultScreen extends StatefulWidget {
  const WalletResultScreen({super.key, required this.wallet});
  final DerivedWallet wallet;

  @override
  State<WalletResultScreen> createState() => _WalletResultScreenState();
}

class _WalletResultScreenState extends State<WalletResultScreen>
    with WidgetsBindingObserver {
  bool _showSecret = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _showSecret) {
      setState(() => _showSecret = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('钱包已生成')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SuccessHeader(),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '显示助记词与中文释义',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text('切到后台时会自动隐藏'),
                            value: _showSecret,
                            onChanged: (value) =>
                                setState(() => _showSecret = value),
                          ),
                          const Divider(),
                          if (_showSecret)
                            _MnemonicContent(mnemonic: widget.wallet.mnemonic)
                          else
                            const _HiddenMnemonic(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '公开地址',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '这些地址可以安全分享。复制操作不会包含助记词。',
                    style: TextStyle(color: Color(0xFF68716D)),
                  ),
                  const SizedBox(height: 14),
                  ...widget.wallet.addresses.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AddressCard(item: item),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.close),
                      label: const Text('清除并返回首页'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      CircleAvatar(
        backgroundColor: Color(0xFF176B4D),
        foregroundColor: Colors.white,
        child: Icon(Icons.check),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '派生完成',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              '数据尚未保存，请妥善完成离线备份',
              style: TextStyle(color: Color(0xFF68716D)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HiddenMnemonic extends StatelessWidget {
  const _HiddenMnemonic();
  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F1ED),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.visibility_off_outlined, color: Color(0xFF68716D)),
        SizedBox(height: 8),
        Text('敏感内容已隐藏', style: TextStyle(color: Color(0xFF68716D))),
      ],
    ),
  );
}

class _MnemonicContent extends StatelessWidget {
  const _MnemonicContent({required this.mnemonic});
  final String mnemonic;
  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(' ');
    final translated = translateMnemonic(mnemonic).split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '任何人获得这些单词都能控制钱包。请勿截图、复制或发送。',
            style: TextStyle(color: Color(0xFF9A3F28), height: 1.45),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            mainAxisExtent: 62,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: words.length,
          itemBuilder: (_, index) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F2),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFE0E2DE)),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF89918D),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        words[index],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        translated[index],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68716D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.item});
  final WalletAddress item;
  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.address));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} 地址已复制'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  item.path,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8580),
                  ),
                ),
                const SizedBox(height: 9),
                SelectableText(
                  item.address,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(context),
            tooltip: '复制地址',
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
    ),
  );
}
