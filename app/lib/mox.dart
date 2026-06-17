// mox.dart — the durable identity of one bonded Mox.
import 'skin.dart';

class Mox {
  final String name;
  final int seed; // drives the whole generative look + sigil
  final int vibe; // 0 calm .. 2 bold (from the tutorial)
  final String token; // unique bond token; doubles as the A2A card id
  final String charter; // the accepted personal charter text
  final String? charterUrl; // where it's hosted after forwarding
  final DateTime bondedAt;

  const Mox({
    required this.name,
    required this.seed,
    required this.vibe,
    required this.token,
    required this.charter,
    required this.bondedAt,
    this.charterUrl,
  });

  MoxSkin get skin => MoxSkin.summon(seed, vibe: vibe);

  Mox copyWith({String? charterUrl}) => Mox(
        name: name,
        seed: seed,
        vibe: vibe,
        token: token,
        charter: charter,
        bondedAt: bondedAt,
        charterUrl: charterUrl ?? this.charterUrl,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'seed': seed,
        'vibe': vibe,
        'token': token,
        'charter': charter,
        'charterUrl': charterUrl,
        'bondedAt': bondedAt.toIso8601String(),
      };

  factory Mox.fromJson(Map<String, dynamic> j) => Mox(
        name: j['name'] as String,
        seed: j['seed'] as int,
        vibe: j['vibe'] as int? ?? 1,
        token: j['token'] as String,
        charter: j['charter'] as String,
        charterUrl: j['charterUrl'] as String?,
        bondedAt: DateTime.parse(j['bondedAt'] as String),
      );
}
