import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/wallet_service.dart';
import '../l10n/app_strings.dart';
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
    SystemSound.play(SystemSoundType.click);
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
    final strings = AppStrings.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.text('discardTitle')),
            content: Text(
              strings.text('discardMessage', {'count': _flips.length}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings.text('continueRecording')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings.text('discard')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopScope(
      canPop: _flips.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit() && context.mounted) {
          setState(_flips.clear);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            strings.text('coinFlipTitle', {'count': widget.flipCount}),
          ),
          actions: [
            if (_flips.isNotEmpty)
              IconButton(
                onPressed: _working
                    ? null
                    : () => setState(() => _flips.removeLast()),
                tooltip: strings.text('undoLast'),
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
  }

  Widget _introView(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
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
          strings.text('prepareCoin'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          strings.text('coinIntro'),
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
                    strings.text('coinMapping', {'count': widget.flipCount}),
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
            label: Text(strings.text('startRecording')),
          ),
        ),
      ],
    );
  }

  Widget _progressView(BuildContext context) {
    final strings = AppStrings.of(context);
    final remaining = widget.flipCount - _flips.length;
    final headsCount = _flips.where((heads) => heads).length;
    final tailsCount = _flips.length - headsCount;
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
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          _working
              ? strings.text('recordComplete')
              : strings.text('flipNumber', {'count': _flips.length + 1}),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _working
              ? strings.text('derivingWallet')
              : strings.text('chooseFace'),
          textAlign: TextAlign.center,
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
                  label: strings.text('heads'),
                  bit: '0',
                  count: headsCount,
                  color: const Color(0xFF176B4D),
                  onTap: () => _record(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CoinButton(
                  label: strings.text('tails'),
                  bit: '1',
                  count: tailsCount,
                  color: const Color(0xFF9A6514),
                  onTap: () => _record(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            strings.text('remaining', {'count': remaining}),
            style: const TextStyle(color: Color(0xFF68716D)),
          ),
        ],
        const Spacer(),
        if (_flips.isNotEmpty)
          _RecentFlips(flips: _flips, title: strings.text('recentResults')),
      ],
    );
  }
}

class _CoinButton extends StatelessWidget {
  const _CoinButton({
    required this.label,
    required this.bit,
    required this.count,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String bit;
  final int count;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label, $bit, $count',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.of(context).text('recordedAs', {'bit': bit}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '× $count',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RecentFlips extends StatelessWidget {
  const _RecentFlips({required this.flips, required this.title});
  final List<bool> flips;
  final String title;
  @override
  Widget build(BuildContext context) {
    final recent = flips.length > 8 ? flips.sublist(flips.length - 8) : flips;
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Color(0xFF68716D)),
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
                    heads ? '0' : '1',
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
