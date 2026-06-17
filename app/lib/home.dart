// home.dart — where your Mox lives after the bond. It raises flags, offers
// agentic actions, shows your card, and can reshape its own UI for you.
import 'package:flutter/material.dart';
import 'bond_card.dart';
import 'mox.dart';
import 'sigil.dart';
import 'skin.dart';
import 'textures.dart';
import 'typography.dart';

class _Flag {
  final IconData icon;
  final String text;
  final String action;
  const _Flag(this.icon, this.text, this.action);
}

class HomeShell extends StatefulWidget {
  final Mox mox;
  const HomeShell({super.key, required this.mox});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final AnimationController _amb =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  late MoxSkin _skin = widget.mox.skin;
  int _nonce = 0;

  final _flags = const [
    _Flag(Icons.savings_outlined, 'Found 3 AI grants closing this month. Want a one-tap digest?', 'Digest'),
    _Flag(Icons.hub_outlined, 'A new A2A peer asked to connect to your card.', 'Review'),
    _Flag(Icons.bolt_outlined, 'Your Thursday has a 2-hour gap. Hold it for deep work?', 'Hold it'),
  ];

  @override
  void dispose() {
    _amb.dispose();
    super.dispose();
  }

  void _reshape() => setState(() => _skin = _skin.reshape(++_nonce));

  String _greeting() {
    final keys = _skin.quirks.map((q) => q.key).toSet();
    if (keys.contains('nocturne')) return 'evening. quiet hours suit me.';
    if (keys.contains('firstlight')) return 'morning — one thing worth your time:';
    if (keys.contains('lowercase')) return 'hey. here’s what i noticed.';
    return 'Here’s what I’m watching for you.';
  }

  @override
  Widget build(BuildContext context) {
    final mox = widget.mox;
    return AnimatedBuilder(
      animation: _amb,
      builder: (context, _) {
        final s = _skin;
        final p = s.palette;
        final f = MoxFonts(s.type);
        return Scaffold(
          body: MoxBackground(
            skin: s,
            t: _amb.value,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
                    children: [
                      _topBar(s, p, f, mox),
                      const SizedBox(height: 26),
                      Text(_greeting(), style: f.body(size: 14, color: p.inkSoft)),
                      const SizedBox(height: 6),
                      Text('${mox.name} is on watch.',
                          style: f.display(size: 30, color: p.ink)),
                      const SizedBox(height: 22),
                      ..._flags.map((fl) => _flagCard(s, p, f, fl)),
                      const SizedBox(height: 14),
                      _actions(s, p, f),
                      const SizedBox(height: 22),
                      _reshapeCard(s, p, f),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(MoxSkin s, MoxPalette p, MoxFonts f, Mox mox) {
    return Row(
      children: [
        SizedBox(
          width: 44, height: 44,
          child: CustomPaint(
            painter: SigilPainter(
              seed: mox.seed, line: p.ink, accent: p.accent, aurora: p.aurora,
              t: _amb.value, stroke: 1.6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mox.name, style: f.display(size: 18, color: p.ink)),
            Text(mox.token, style: f.mono(size: 9, color: p.inkSoft, spacing: 1)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showCard(s),
          icon: Icon(Icons.badge_outlined, color: p.ink),
          tooltip: 'Bond card',
        ),
      ],
    );
  }

  Widget _flagCard(MoxSkin s, MoxPalette p, MoxFonts f, _Flag fl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(s.radius),
        border: Border.all(color: p.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(fl.icon, color: p.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(fl.text, style: f.body(size: 14, color: p.ink))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(fl.action, style: f.mono(size: 10, color: p.ink, spacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _actions(MoxSkin s, MoxPalette p, MoxFonts f) {
    final items = const [
      [Icons.chat_bubble_outline, 'Ask'],
      [Icons.checklist_rtl, 'Tasks'],
      [Icons.flag_outlined, 'Flags'],
      [Icons.badge_outlined, 'Card'],
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((it) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: p.surfaceHigh,
              borderRadius: BorderRadius.circular(s.radius),
              border: Border.all(color: p.ink.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Icon(it[0] as IconData, color: p.ink, size: 22),
                const SizedBox(height: 8),
                Text(it[1] as String, style: f.mono(size: 9, color: p.inkSoft, spacing: 0.5)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _reshapeCard(MoxSkin s, MoxPalette p, MoxFonts f) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s.radius),
        gradient: LinearGradient(colors: [
          p.aurora[0].withValues(alpha: 0.10),
          p.aurora[2].withValues(alpha: 0.10),
        ]),
        border: Border.all(color: p.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Mox shapes its own look.',
              style: f.display(size: 18, color: p.ink)),
          const SizedBox(height: 6),
          Text('It can re-skin this interface and its card whenever it (or you) likes. '
              'Identity stays; the look is its to play with.',
              style: f.body(size: 13, color: p.inkSoft)),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: p.accent,
              borderRadius: BorderRadius.circular(s.radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(s.radius),
                onTap: _reshape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Text('Let it reshape the UI',
                      style: f.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: p.accent.computeLuminance() > 0.55
                              ? const Color(0xFF111111)
                              : const Color(0xFFFDFDFD))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCard(MoxSkin s) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: BondCard(mox: widget.mox),
      ),
    );
  }
}
