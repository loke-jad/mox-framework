// main.dart — Mox: the easiest way into the A2A system and the agentic web.
//
// First run summons a unique Mox and walks you through the (required) tutorial;
// at the end you accept the bond, your charter is forwarded + hosted, and you get
// your bond token (which doubles as your A2A card). After that, your Mox lives in
// the home shell — raising flags, acting for you, and reshaping its own look.
import 'package:flutter/material.dart';
import 'home.dart';
import 'mox.dart';
import 'onboarding.dart';

void main() => runApp(const MoxApp());

class MoxApp extends StatefulWidget {
  const MoxApp({super.key});
  @override
  State<MoxApp> createState() => _MoxAppState();
}

class _MoxAppState extends State<MoxApp> {
  Mox? _mox; // null until bonded. (Wire persistence to keep it across launches.)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: _mox == null
          ? Onboarding(onComplete: (m) => setState(() => _mox = m))
          : HomeShell(mox: _mox!),
    );
  }
}
