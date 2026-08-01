import 'package:flutter/material.dart';

import 'coin_flip_screen.dart';
import 'random_wallet_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      _Logo(),
                      SizedBox(width: 12),
                      Text(
                        'DICE WALLET',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    '离线创建你的钱包',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '选择熵源与助记词长度。生成、派生和展示全程仅在本机内存中完成。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF59635E),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel(
                    title: '系统安全随机数',
                    icon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 10),
                  _OptionGrid(
                    options: [
                      _Option(
                        '随机生成',
                        '12 词',
                        '128 位系统安全熵',
                        Icons.auto_awesome_outlined,
                        () => _open(
                          context,
                          const RandomWalletScreen(bitLength: 128),
                        ),
                      ),
                      _Option(
                        '随机生成',
                        '24 词',
                        '256 位系统安全熵',
                        Icons.auto_awesome_outlined,
                        () => _open(
                          context,
                          const RandomWalletScreen(bitLength: 256),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel(
                    title: '手工抛硬币',
                    icon: Icons.toll_outlined,
                  ),
                  const SizedBox(height: 10),
                  _OptionGrid(
                    options: [
                      _Option(
                        '抛硬币',
                        '12 词',
                        '记录 128 次结果',
                        Icons.toll_outlined,
                        () => _open(
                          context,
                          const CoinFlipScreen(flipCount: 128),
                        ),
                      ),
                      _Option(
                        '抛硬币',
                        '24 词',
                        '记录 256 次结果',
                        Icons.toll_outlined,
                        () => _open(
                          context,
                          const CoinFlipScreen(flipCount: 256),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _PrivacyNote(),
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
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFF17201C),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.casino_outlined, color: Color(0xFFF6C453)),
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
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
      final width = constraints.maxWidth >= 560
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options
            .map(
              (item) => SizedBox(
                width: width,
                child: _OptionCard(option: item),
              ),
            )
            .toList(),
      );
    },
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option});
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
                  Row(
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
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
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.lock_outline, size: 18, color: Color(0xFF68716D)),
      SizedBox(width: 9),
      Expanded(
        child: Text(
          '不联网、不保存、不上传。退出结果页后，页面将释放钱包数据引用。',
          style: TextStyle(color: Color(0xFF68716D), height: 1.5),
        ),
      ),
    ],
  );
}
