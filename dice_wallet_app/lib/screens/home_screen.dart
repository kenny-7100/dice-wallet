import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'coin_flip_screen.dart';
import 'random_wallet_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _Logo(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'TOSSKEY',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showLanguagePicker(context),
                        tooltip: strings.text('language'),
                        icon: const Icon(Icons.language),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    strings.text('createWallet'),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.text('homeDescription'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF59635E),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(
                    title: strings.text('secureRandom'),
                    icon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 10),
                  _OptionGrid(
                    options: [
                      _Option(
                        strings.text('randomGenerate'),
                        strings.text('wordCount', {'count': 12}),
                        strings.text('secureEntropyBits', {'count': 128}),
                        Icons.auto_awesome_outlined,
                        () => _open(
                          context,
                          const RandomWalletScreen(bitLength: 128),
                        ),
                      ),
                      _Option(
                        strings.text('randomGenerate'),
                        strings.text('wordCount', {'count': 24}),
                        strings.text('secureEntropyBits', {'count': 256}),
                        Icons.auto_awesome_outlined,
                        () => _open(
                          context,
                          const RandomWalletScreen(bitLength: 256),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(
                    title: strings.text('manualCoinFlip'),
                    icon: Icons.toll_outlined,
                  ),
                  const SizedBox(height: 10),
                  _OptionGrid(
                    options: [
                      _Option(
                        strings.text('coinFlip'),
                        strings.text('wordCount', {'count': 12}),
                        strings.text('recordResults', {'count': 128}),
                        Icons.toll_outlined,
                        () => _open(
                          context,
                          const CoinFlipScreen(flipCount: 128),
                        ),
                      ),
                      _Option(
                        strings.text('coinFlip'),
                        strings.text('wordCount', {'count': 24}),
                        strings.text('recordResults', {'count': 256}),
                        Icons.toll_outlined,
                        () => _open(
                          context,
                          const CoinFlipScreen(flipCount: 256),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _PrivacyNote(text: strings.text('privacyNote')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _showLanguagePicker(BuildContext context) async {
    final strings = AppStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  children: [
                    Text(
                      strings.text('language'),
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.text('languageDescription'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF68716D)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(strings.text('systemDefault')),
                      leading: const Icon(Icons.phone_iphone),
                      trailing: localeController.locale == null
                          ? const Icon(Icons.check, color: Color(0xFF176B4D))
                          : null,
                      onTap: () async {
                        await localeController.select(null);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    ),
                    ...supportedLanguageCodes.map(
                      (code) => ListTile(
                        title: Text(languageNames[code]!),
                        trailing: localeController.locale?.languageCode == code
                            ? const Icon(Icons.check, color: Color(0xFF176B4D))
                            : null,
                        onTap: () async {
                          await localeController.select(Locale(code));
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      'assets/brand/dice-wallet-icon.png',
      width: 42,
      height: 42,
      fit: BoxFit.cover,
      semanticLabel: 'TossKey',
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: const Color(0xFF176B4D)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    ],
  );
}

class _Option {
  const _Option(this.title, this.badge, this.subtitle, this.icon, this.onTap);
  final String title;
  final String badge;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.options});
  final List<_Option> options;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 600
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options
            .map((item) => SizedBox(width: width, child: _OptionCard(item)))
            .toList(),
      );
    },
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard(this.option);
  final _Option option;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: option.onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFE9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(option.icon, color: const Color(0xFF176B4D)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        option.badge,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A6514),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    style: const TextStyle(color: Color(0xFF68716D)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7B8580)),
          ],
        ),
      ),
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.lock_outline, size: 18, color: Color(0xFF68716D)),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF68716D), height: 1.5),
        ),
      ),
    ],
  );
}
