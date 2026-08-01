import 'package:flutter/material.dart';

import '../core/wallet_service.dart';
import 'wallet_result_screen.dart';

class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key, required this.flipCount});
  final int flipCount;

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> {
  final List<bool> _flips = [];
  bool _started = false;
  bool _working = false;

  void _record(bool heads) {
    if (_working || _flips.length == widget.flipCount) return;
    setState(() => _flips.add(heads));
    if (_flips.length == widget.flipCount) _finish();
  }

  Future<void> _finish() async {
    setState(() => _working = true);
    final entropy = WalletService().entropyFromCoinFlips(_flips);
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

  Future<bool> _confirmExit() async {
    if (_flips.isEmpty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('放弃当前记录？'),
            content: Text('已记录 ${_flips.length} 次结果，退出后无法恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续记录'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('放弃'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _flips.isEmpty,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _confirmExit() && context.mounted) {
        setState(_flips.clear);
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('${widget.flipCount} 次抛硬币'),
        actions: [
          if (_flips.isNotEmpty)
            IconButton(
              onPressed: _working
                  ? null
                  : () => setState(() => _flips.removeLast()),
              tooltip: '撤销上一次',
              icon: const Icon(Icons.undo),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: _started ? _progressView(context) : _introView(context),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _introView(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDC5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.toll_outlined,
          size: 40,
          color: Color(0xFF9A6514),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        '准备一枚普通硬币',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      const Text(
        '每次在现实中抛硬币，然后点击对应结果。请保持环境安静、专注，避免跳过或凭感觉输入。',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.55, color: Color(0xFF59635E)),
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF176B4D)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '正面记为 0，反面记为 1。需要连续记录 ${widget.flipCount} 次；输入过程中可随时撤销上一次。',
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => setState(() => _started = true),
          icon: const Icon(Icons.play_arrow),
          label: const Text('开始记录'),
        ),
      ),
    ],
  );

  Widget _progressView(BuildContext context) {
    final remaining = widget.flipCount - _flips.length;
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _flips.length / widget.flipCount,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFDDE1DE),
                  color: const Color(0xFF176B4D),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${_flips.length} / ${widget.flipCount}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          _working ? '记录完成' : '第 ${_flips.length + 1} 次',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _working ? '正在派生钱包地址…' : '抛出硬币后，选择朝上的一面',
          style: const TextStyle(color: Color(0xFF68716D)),
        ),
        const Spacer(),
        if (_working)
          const CircularProgressIndicator()
        else ...[
          Row(
            children: [
              Expanded(
                child: _CoinButton(
                  label: '正面',
                  bit: '0',
                  color: const Color(0xFF176B4D),
                  onTap: () => _record(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CoinButton(
                  label: '反面',
                  bit: '1',
                  color: const Color(0xFF9A6514),
                  onTap: () => _record(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '还剩 $remaining 次',
            style: const TextStyle(color: Color(0xFF68716D)),
          ),
        ],
        const Spacer(),
        if (_flips.isNotEmpty) _RecentFlips(flips: _flips),
      ],
    );
  }
}

class _CoinButton extends StatelessWidget {
  const _CoinButton({
    required this.label,
    required this.bit,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String bit;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label，记为 $bit',
    child: SizedBox(
      height: 138,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '记为 $bit',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RecentFlips extends StatelessWidget {
  const _RecentFlips({required this.flips});
  final List<bool> flips;
  @override
  Widget build(BuildContext context) {
    final recent = flips.length > 8 ? flips.sublist(flips.length - 8) : flips;
    return Column(
      children: [
        const Text(
          '最近记录',
          style: TextStyle(fontSize: 13, color: Color(0xFF68716D)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: recent
              .map(
                (heads) => Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: heads
                        ? const Color(0xFFE4EFE9)
                        : const Color(0xFFFFEDC5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    heads ? '正' : '反',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: heads
                          ? const Color(0xFF176B4D)
                          : const Color(0xFF9A6514),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
