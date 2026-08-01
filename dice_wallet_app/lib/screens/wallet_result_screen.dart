import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/mnemonic_translations.dart';
import '../core/wallet_service.dart';
import '../l10n/app_strings.dart';

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
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('walletGenerated'))),
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
                              title: Text(
                                strings.text('showMnemonic'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(strings.text('hideInBackground')),
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
                      strings.text('publicAddresses'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.text('publicAddressHelp'),
                      style: const TextStyle(color: Color(0xFF68716D)),
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
                        label: Text(strings.text('clearAndHome')),
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
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFF176B4D),
          foregroundColor: Colors.white,
          child: Icon(Icons.check),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.text('derivationComplete'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                strings.text('backupReminder'),
                style: const TextStyle(color: Color(0xFF68716D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.visibility_off_outlined, color: Color(0xFF68716D)),
        const SizedBox(height: 8),
        Text(
          AppStrings.of(context).text('sensitiveHidden'),
          style: const TextStyle(color: Color(0xFF68716D)),
        ),
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
    final strings = AppStrings.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            strings.text('secretWarning'),
            style: const TextStyle(color: Color(0xFF9A3F28), height: 1.45),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, String>>(
          future: MnemonicTranslations.load(languageCode),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final translations = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisExtent: 66,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: words.length,
              itemBuilder: (_, index) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                            textDirection: TextDirection.ltr,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            translations[words[index]] ?? words[index],
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
            );
          },
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
          content: Text(
            AppStrings.of(context).text('addressCopied', {
              'name': _localizedAddressName(context, item.name),
            }),
          ),
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
                  _localizedAddressName(context, item.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  item.path,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8580),
                  ),
                ),
                const SizedBox(height: 9),
                SelectableText(
                  item.address,
                  textDirection: TextDirection.ltr,
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
            tooltip: AppStrings.of(context).text('copyAddress'),
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
    ),
  );

  String _localizedAddressName(BuildContext context, String name) {
    const keys = {
      'Bitcoin Native SegWit': 'bitcoinNativeSegwit',
      'Bitcoin Taproot': 'bitcoinTaproot',
      'Ethereum': 'ethereum',
      'Solana': 'solana',
      'TRON': 'tron',
    };
    return AppStrings.of(context).text(keys[name] ?? name);
  }
}
