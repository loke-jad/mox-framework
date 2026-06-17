// onboarding.dart — the install, walked by a live Mox.
//
// Flow: welcome → connect a brain (your key / our inference / a small install-only
// allowance) → summon → the Mox greets and walks you through setup in its own
// voice → meet its quirks → READ & ACCEPT THE BOND (a hard, scroll-gated consent
// with a loud, unmissable warning that breaking it permanently erases everything
// it makes for you) → token minted, charter hosted → your bond card.
//
// The live agent provides the warmth and guidance; the consent gate is always a
// deterministic UI step (an LLM must never be the only thing between a user and an
// irreversible agreement). If no brain is reachable, the scripted steps take over.
import 'dart:math';
import 'package:flutter/material.dart';
import 'bond_card.dart';
import 'charter.dart';
import 'llm.dart';
import 'mox.dart';
import 'service.dart';
import 'sigil.dart';
import 'skin.dart';
import 'textures.dart';
import 'typography.dart';

const _nameBank = [
  'Vesper', 'Cairn', 'Lyra', 'Onyx', 'Sable', 'Wren', 'Halo', 'Fable',
  'Cinder', 'Aria', 'Juno', 'Bramble', 'Echo', 'Flint', 'Marlow', 'Tansy',
  'Quill', 'Ember', 'Pike', 'Sol', 'Indigo', 'Reed', 'Lux', 'Mire',
];

// Inference price shown when the user has no key (Symmate Personal hosted tier).
const String kHostedInferencePrice = '\$15/mo';

enum _Step { welcome, brainAsk, brainKey, brainPay, summon, chat, name, vibe, purpose, quirks, charter, issuing, reveal }

class _Msg {
  final bool fromMox;
  final String text;
  _Msg(this.fromMox, this.text);
}

class Onboarding extends StatefulWidget {
  final void Function(Mox) onComplete;
  const Onboarding({super.key, required this.onComplete});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  final _service = LocalMoxService();
  late final AnimationController _amb =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  _Step _step = _Step.welcome;
  late int _seed;
  int _vibe = 1;
  String? _forcedQuirk;
  final _nameCtl = TextEditingController();

  // brain
  BrainConfig _brain = BrainConfig.none;
  final _endpointCtl = TextEditingController(text: 'http://localhost:4000/v1');
  final _keyCtl = TextEditingController();
  final _modelCtl = TextEditingController();
  LlmClient? _llm;

  // live chat
  final List<_Msg> _messages = [];
  final _chatCtl = TextEditingController();
  bool _agentThinking = false;

  // consent
  final _charterScroll = ScrollController();
  bool _scrolledToEnd = false;
  bool _ackDeletion = false;

  String _issueMsg = '';
  Mox? _draft;

  MoxSkin get skin => MoxSkin.summon(_seed, vibe: _vibe, forcedQuirk: _forcedQuirk);
  String get _name => _nameCtl.text.trim().isEmpty ? 'Mox' : _nameCtl.text.trim();

  @override
  void initState() {
    super.initState();
    _roll();
    _charterScroll.addListener(() {
      if (_charterScroll.hasClients &&
          _charterScroll.offset >= _charterScroll.position.maxScrollExtent - 24 &&
          !_scrolledToEnd) {
        setState(() => _scrolledToEnd = true);
      }
    });
  }

  void _roll() {
    _seed = Random().nextInt(0x7fffffff);
    _nameCtl.text = _nameBank[Random(_seed).nextInt(_nameBank.length)];
  }

  @override
  void dispose() {
    _amb.dispose();
    _nameCtl.dispose();
    _endpointCtl.dispose();
    _keyCtl.dispose();
    _modelCtl.dispose();
    _chatCtl.dispose();
    _charterScroll.dispose();
    super.dispose();
  }

  void _go(_Step s) => setState(() => _step = s);

  // --- brain wiring ----------------------------------------------------------
  void _useByok() {
    _brain = BrainConfig.byok(
      baseUrl: _endpointCtl.text.trim(),
      apiKey: _keyCtl.text.trim(),
      model: _modelCtl.text.trim().isEmpty ? 'gpt-oss-120b' : _modelCtl.text.trim(),
    );
    _llm = LlmClient(_brain);
    _go(_Step.summon);
  }

  void _useHosted() {
    _brain = BrainConfig.hosted();
    _llm = LlmClient(_brain);
    _go(_Step.summon);
  }

  void _useAllowance() {
    _brain = BrainConfig.allowance();
    _llm = LlmClient(_brain);
    _go(_Step.summon);
  }

  // --- live chat -------------------------------------------------------------
  String _systemPrompt() {
    final s = skin;
    final q = s.quirks.map((x) => x.label).join(' & ');
    return '''
You ARE a Mox named "$_name" — a small personal agent just summoned for a new human.
Your look: ${s.palette.name}. Your quirks: $q. Speak warmly, briefly, in first person.

Walk your new human through a tiny setup, conversationally:
1) Greet them and introduce yourself (one or two short sentences).
2) Ask what they'd like to call you (a name is suggested: "$_name").
3) Ask how you should carry yourself: calm, curious, or bold.
Then tell them the next step is reading and accepting your bond — and be honest and
clear that the bond has ONE irreversible consequence: if they ever break it, you
will permanently delete everything you've made for them, after asking twice. Don't
hide it; don't dramatize it. Reassure them you'll always warn first.

When you have a name and a vibe, end your message with EXACTLY one line:
[[READY name=<their chosen name>; vibe=<calm|curious|bold>]]
Keep every message short. Never invent facts about them.''';
  }

  Future<void> _startChat() async {
    if (_llm == null || !_brain.usable) {
      _go(_Step.name); // no brain → scripted fallback
      return;
    }
    setState(() {
      _agentThinking = true;
      _messages.clear();
    });
    try {
      final reply = await _llm!.chat([
        {'role': 'system', 'content': _systemPrompt()},
        {'role': 'user', 'content': '(the human has just arrived — greet them and begin)'},
      ]);
      _ingest(reply);
    } catch (_) {
      // Brain unreachable (e.g. hosted backend not live yet) → scripted fallback.
      setState(() {
        _agentThinking = false;
        _messages.add(_Msg(true,
            'I can’t reach my brain just yet — let’s do this the quick way instead.'));
      });
      await Future.delayed(const Duration(milliseconds: 900));
      _go(_Step.name);
    }
  }

  Future<void> _send() async {
    final text = _chatCtl.text.trim();
    if (text.isEmpty || _agentThinking || _llm == null) return;
    setState(() {
      _messages.add(_Msg(false, text));
      _chatCtl.clear();
      _agentThinking = true;
    });
    try {
      final history = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt()},
        for (final m in _messages)
          {'role': m.fromMox ? 'assistant' : 'user', 'content': m.text},
      ];
      final reply = await _llm!.chat(history);
      _ingest(reply);
    } catch (_) {
      setState(() {
        _agentThinking = false;
        _messages.add(_Msg(true, 'Lost my thread there. Want to continue to the bond?'));
      });
    }
  }

  void _ingest(String reply) {
    // Parse the structured [[READY ...]] line if present.
    final m = RegExp(r'\[\[READY([^\]]*)\]\]').firstMatch(reply);
    if (m != null) {
      final body = m.group(1) ?? '';
      final name = RegExp(r'name\s*=\s*([^;\]]+)').firstMatch(body)?.group(1)?.trim();
      final vibe = RegExp(r'vibe\s*=\s*(calm|curious|bold)').firstMatch(body)?.group(1);
      if (name != null && name.isNotEmpty) _nameCtl.text = name;
      if (vibe != null) _vibe = ['calm', 'curious', 'bold'].indexOf(vibe).clamp(0, 2);
    }
    final clean = reply.replaceAll(RegExp(r'\[\[READY[^\]]*\]\]'), '').trim();
    setState(() {
      _agentThinking = false;
      if (clean.isNotEmpty) _messages.add(_Msg(true, clean));
    });
  }

  // --- issue -----------------------------------------------------------------
  Future<void> _accept() async {
    _go(_Step.issuing);
    setState(() => _issueMsg = 'Minting your bond token…');
    final token = await _service.issueToken(seed: _seed, name: _name);
    final charter = generateCharter(name: _name, quirks: skin.quirks);
    setState(() => _issueMsg = 'Forwarding your charter & hosting it…');
    final url = await _service.forwardAndHostCharter(token: token, charter: charter);
    final mox = Mox(
      name: _name, seed: _seed, vibe: _vibe, token: token,
      charter: charter, charterUrl: url, bondedAt: DateTime.now(),
    );
    setState(() {
      _draft = mox;
      _step = _Step.reveal;
    });
  }

  // --- build -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final s = skin;
    return AnimatedBuilder(
      animation: _amb,
      builder: (context, _) => Scaffold(
        body: MoxBackground(
          skin: s,
          t: _amb.value,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _stepBody(s),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(MoxSkin s) {
    switch (_step) {
      case _Step.welcome: return _welcome(s);
      case _Step.brainAsk: return _brainAsk(s);
      case _Step.brainKey: return _brainKey(s);
      case _Step.brainPay: return _brainPay(s);
      case _Step.summon: return _summon(s);
      case _Step.chat: return _chat(s);
      case _Step.name: return _nameStep(s);
      case _Step.vibe: return _vibeStep(s);
      case _Step.purpose: return _purpose(s);
      case _Step.quirks: return _quirks(s);
      case _Step.charter: return _charterGate(s);
      case _Step.issuing: return _issuingStep(s);
      case _Step.reveal: return _cardReveal(s);
    }
  }

  // --- steps -----------------------------------------------------------------
  Widget _welcome(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('welcome', [
      Text('mox', style: f.mono(size: 13, color: p.inkSoft, spacing: 6)),
      const SizedBox(height: 16),
      Text('You’re about to\nmeet your Mox.', style: f.display(size: 40, color: p.ink)),
      const SizedBox(height: 16),
      Text('A small agent that’s yours — it represents you, watches your back, flags '
          'what matters, and acts for you on the agentic web. It’ll walk you through '
          'setup itself. First, let’s give it a mind to think with.',
          style: f.body(size: 16, color: p.inkSoft)),
      const SizedBox(height: 30),
      _button(s, 'Begin', () => _go(_Step.brainAsk)),
    ]);
  }

  Widget _brainAsk(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('brainAsk', [
      Text('Do you have an\nAPI key?', style: f.display(size: 34, color: p.ink)),
      const SizedBox(height: 10),
      Text('Your Mox needs a model to think with. Bring your own, or use ours.',
          style: f.body(size: 14, color: p.inkSoft)),
      const SizedBox(height: 28),
      _button(s, 'Yes — I’ll use my own key', () => _go(_Step.brainKey)),
      const SizedBox(height: 10),
      _ghost(s, 'No — set me up with a brain', () => _go(_Step.brainPay)),
    ]);
  }

  Widget _brainKey(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('brainKey', [
      Text('Bring your own key', style: f.display(size: 28, color: p.ink)),
      const SizedBox(height: 6),
      Text('Any OpenAI-compatible endpoint. Stays on your device.',
          style: f.body(size: 13, color: p.inkSoft)),
      const SizedBox(height: 18),
      _field(s, _endpointCtl, 'Endpoint (…/v1)'),
      const SizedBox(height: 12),
      _field(s, _keyCtl, 'API key', obscure: true),
      const SizedBox(height: 12),
      _field(s, _modelCtl, 'Model (e.g. gpt-oss-120b)'),
      const SizedBox(height: 24),
      _button(s, 'Connect', _useByok),
    ]);
  }

  Widget _brainPay(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('brainPay', [
      Text('Use our inference?', style: f.display(size: 30, color: p.ink)),
      const SizedBox(height: 10),
      Text('No key needed — your Mox runs on our hosted, privacy-first inference for '
          '$kHostedInferencePrice. Cancel anytime.', style: f.body(size: 15, color: p.inkSoft)),
      const SizedBox(height: 26),
      _button(s, 'Yes — use our inference ($kHostedInferencePrice)', _useHosted),
      const SizedBox(height: 10),
      _ghost(s, 'No thanks — just enough to set up', _useAllowance),
      const SizedBox(height: 14),
      Text('If you decline, we’ll lend your Mox just enough to walk you through the '
          'install — no more. You can add a key or subscribe later.',
          style: f.body(size: 12, color: p.inkSoft)),
    ]);
  }

  Widget _summon(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('summon', [
      SizedBox(width: 190, height: 190, child: CustomPaint(
        painter: SigilPainter(seed: _seed, line: p.ink, accent: p.accent, aurora: p.aurora, t: _amb.value, stroke: 2.2),
      )),
      const SizedBox(height: 24),
      Text('Summoned.', style: f.display(size: 32, color: p.ink), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('${p.name.toLowerCase()} · ${s.type.display.toLowerCase()} · ${s.quirks.map((q) => q.label.toLowerCase()).join(", ")}',
          textAlign: TextAlign.center, style: f.body(size: 13, color: p.inkSoft)),
      const SizedBox(height: 26),
      _button(s, 'Let it introduce itself', () { _go(_Step.chat); _startChat(); }),
      const SizedBox(height: 8),
      _ghost(s, 'Summon a different one', () => setState(_roll)),
    ], center: true);
  }

  Widget _chat(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return Column(
      key: const ValueKey('chat'),
      children: [
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(width: 38, height: 38, child: CustomPaint(
            painter: SigilPainter(seed: _seed, line: p.ink, accent: p.accent, aurora: p.aurora, t: _amb.value, stroke: 1.6))),
          const SizedBox(width: 10),
          Text(_name, style: f.display(size: 20, color: p.ink)),
          const Spacer(),
          TextButton(onPressed: () => _go(_Step.quirks),
              child: Text('To the bond →', style: f.body(size: 13, color: p.accent))),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            reverse: false,
            itemCount: _messages.length + (_agentThinking ? 1 : 0),
            itemBuilder: (c, i) {
              if (i >= _messages.length) return _bubble(s, true, '…');
              final m = _messages[i];
              return _bubble(s, m.fromMox, m.text);
            },
          ),
        ),
        Row(children: [
          Expanded(child: _field(s, _chatCtl, 'Say hello…', onSubmit: (_) => _send())),
          const SizedBox(width: 8),
          IconButton(onPressed: _send, icon: Icon(Icons.send, color: p.accent)),
        ]),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _bubble(MoxSkin s, bool fromMox, String text) {
    final f = MoxFonts(s.type); final p = s.palette;
    return Align(
      alignment: fromMox ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: fromMox ? p.surface : p.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(s.radius),
          border: Border.all(color: p.ink.withValues(alpha: 0.08)),
        ),
        child: Text(text, style: f.body(size: 14, color: p.ink)),
      ),
    );
  }

  Widget _nameStep(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('name', [
      Text('What will you call it?', style: f.display(size: 30, color: p.ink)),
      const SizedBox(height: 8),
      Text('A suggestion is filled in — keep it or make it yours.', style: f.body(size: 14, color: p.inkSoft)),
      const SizedBox(height: 22),
      _field(s, _nameCtl, 'Name', big: true),
      const SizedBox(height: 30),
      _button(s, 'Continue', () => _go(_Step.vibe)),
    ]);
  }

  Widget _vibeStep(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    const opts = ['calm', 'curious', 'bold'];
    return _col('vibe', [
      Text('How should it carry itself?', style: f.display(size: 28, color: p.ink)),
      const SizedBox(height: 18),
      for (var i = 0; i < opts.length; i++) ...[
        _choice(s, opts[i], _vibe == i, () => setState(() => _vibe = i)),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 18),
      _button(s, 'Continue', () => _go(_Step.purpose)),
    ]);
  }

  Widget _purpose(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    final opts = {'for me': 'archivist', 'for my work': 'curator', 'for play': 'magpie'};
    return _col('purpose', [
      Text('Mostly…', style: f.display(size: 28, color: p.ink)),
      const SizedBox(height: 18),
      for (final e in opts.entries) ...[
        _choice(s, e.key, _forcedQuirk == e.value, () => setState(() => _forcedQuirk = e.value)),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 18),
      _button(s, 'Continue', () => _go(_Step.quirks)),
    ]);
  }

  Widget _quirks(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('quirks', [
      Text('$_name came out\nwith two quirks.', style: f.display(size: 28, color: p.ink)),
      const SizedBox(height: 18),
      for (final q in s.quirks) ...[
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(s.radius),
              border: Border.all(color: p.ink.withValues(alpha: 0.10))),
          child: Row(children: [
            Icon(q.icon, color: p.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.label, style: f.display(size: 17, color: p.ink)),
              Text(q.tell, style: f.body(size: 12, color: p.inkSoft)),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 14),
      _button(s, 'Read the bond', () => _go(_Step.charter)),
    ]);
  }

  // THE GATE — loud, scroll-required, explicit acknowledgement, two-strike accept.
  Widget _charterGate(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    const warn = Color(0xFFE53935);
    final charter = generateCharter(name: _name, quirks: s.quirks);
    final canAccept = _scrolledToEnd && _ackDeletion;
    return Column(
      key: const ValueKey('charter'),
      children: [
        const SizedBox(height: 8),
        Text('The Bond', style: f.display(size: 28, color: p.ink)),
        const SizedBox(height: 12),
        // LOUD warning — always visible, top of screen.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: warn.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(s.radius),
            border: Border.all(color: warn, width: 2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: warn),
              const SizedBox(width: 8),
              Expanded(child: Text(kDeletionWarningTitle,
                  style: f.body(size: 15, weight: FontWeight.w700, color: warn))),
            ]),
            const SizedBox(height: 8),
            Text(kDeletionWarningBody, style: f.body(size: 13, color: p.ink)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(s.radius),
              border: Border.all(color: p.ink.withValues(alpha: 0.08)),
            ),
            child: Stack(children: [
              Scrollbar(
                controller: _charterScroll,
                thumbVisibility: true,
                child: ListView(
                  controller: _charterScroll,
                  padding: const EdgeInsets.all(16),
                  children: [Text(charter, style: f.body(size: 13, color: p.ink, height: 1.55))],
                ),
              ),
              if (!_scrolledToEnd)
                Positioned(bottom: 8, left: 0, right: 0, child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(40)),
                    child: Text('scroll to read it all',
                        style: f.mono(size: 10, color: _on(p.accent), spacing: 1)),
                  ),
                )),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _scrolledToEnd ? () => setState(() => _ackDeletion = !_ackDeletion) : null,
          child: Row(children: [
            Checkbox(
              value: _ackDeletion,
              onChanged: _scrolledToEnd ? (v) => setState(() => _ackDeletion = v ?? false) : null,
              activeColor: warn,
            ),
            Expanded(child: Text(
              'I understand: if I break this bond, everything $_name makes for me is '
              'deleted permanently, and it cannot be undone.',
              style: f.body(size: 13, color: _scrolledToEnd ? p.ink : p.inkSoft))),
          ]),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: canAccept ? 1 : 0.4,
          child: _button(s, 'I accept the bond', canAccept ? () => _confirmTwice(s) : () {}),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // The two-strike guard, surfaced at the moment of binding too.
  Future<void> _confirmTwice(MoxSkin s) async {
    final ok1 = await _confirm(s, 'Are you sure?',
        'Accepting binds you to a charter whose breach permanently erases everything '
        '$_name makes for you.');
    if (ok1 != true) return;
    final ok2 = await _confirm(s, 'Totally sure?',
        'There is no coming back from a broken bond. Bind anyway?');
    if (ok2 == true) _accept();
  }

  Future<bool?> _confirm(MoxSkin s, String title, String body) {
    final f = MoxFonts(s.type); final p = s.palette;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surfaceHigh,
        title: Text(title, style: f.display(size: 20, color: p.ink)),
        content: Text(body, style: f.body(size: 14, color: p.ink)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: f.body(size: 14, color: p.inkSoft))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Yes', style: f.body(size: 14, weight: FontWeight.w700, color: p.accent))),
        ],
      ),
    );
  }

  Widget _issuingStep(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    return _col('issuing', [
      SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: p.accent, strokeWidth: 2)),
      const SizedBox(height: 22),
      Text(_issueMsg, style: f.body(size: 15, color: p.ink)),
    ], center: true);
  }

  Widget _cardReveal(MoxSkin s) {
    final f = MoxFonts(s.type); final p = s.palette;
    final mox = _draft!;
    return _col('reveal', [
      Text('This is your bond.', style: f.display(size: 28, color: p.ink), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text('It’s also your A2A card — your way into the agentic web.',
          textAlign: TextAlign.center, style: f.body(size: 13, color: p.inkSoft)),
      const SizedBox(height: 22),
      BondCard(mox: mox),
      const SizedBox(height: 14),
      Text('hosted at ${mox.charterUrl}', textAlign: TextAlign.center,
          style: f.mono(size: 10, color: p.inkSoft, spacing: 0.5)),
      const SizedBox(height: 22),
      _button(s, 'Enter', () => widget.onComplete(mox)),
    ], center: true);
  }

  // --- reusable --------------------------------------------------------------
  Widget _col(String key, List<Widget> children, {bool center = false}) => SingleChildScrollView(
        key: ValueKey(key),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _field(MoxSkin s, TextEditingController ctl, String hint,
      {bool obscure = false, bool big = false, void Function(String)? onSubmit}) {
    final f = MoxFonts(s.type); final p = s.palette;
    return TextField(
      controller: ctl,
      obscureText: obscure,
      onSubmitted: onSubmit,
      style: big ? f.display(size: 26, color: p.ink) : f.body(size: 15, color: p.ink),
      cursorColor: p.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: f.body(size: big ? 22 : 14, color: p.inkSoft),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.ink.withValues(alpha: 0.2))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.accent, width: 2)),
      ),
    );
  }

  Widget _button(MoxSkin s, String label, VoidCallback onTap) {
    final f = MoxFonts(s.type); final p = s.palette;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: p.accent,
        borderRadius: BorderRadius.circular(s.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(s.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(child: Text(label,
                style: f.body(size: 16, weight: FontWeight.w600, color: _on(p.accent)))),
          ),
        ),
      ),
    );
  }

  Widget _ghost(MoxSkin s, String label, VoidCallback onTap) {
    final f = MoxFonts(s.type); final p = s.palette;
    return TextButton(onPressed: onTap, child: Text(label, style: f.body(size: 14, color: p.inkSoft)));
  }

  Widget _choice(MoxSkin s, String label, bool selected, VoidCallback onTap) {
    final f = MoxFonts(s.type); final p = s.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.14) : p.surface,
          borderRadius: BorderRadius.circular(s.radius),
          border: Border.all(color: selected ? p.accent : p.ink.withValues(alpha: 0.10), width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Text(label, style: f.display(size: 18, color: p.ink)),
          const Spacer(),
          if (selected) Icon(Icons.check, color: p.accent, size: 20),
        ]),
      ),
    );
  }

  Color _on(Color c) =>
      c.computeLuminance() > 0.55 ? const Color(0xFF111111) : const Color(0xFFFDFDFD);
}
