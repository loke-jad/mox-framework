// service.dart — the seam between the app and the bond backend.
//
// At the end of the (required) tutorial the charter is forwarded to
// justadestination, auto-hosted, and a unique bond token is minted (the token
// doubles as the A2A card id). This file is where that happens. The default
// implementation runs fully locally (deterministic, offline-friendly) so the app
// works out of the box; swap `LocalMoxService` for a real HTTP client to go live
// against the Mox-Framework backend — the call sites don't change.
import 'dart:math';

abstract class MoxService {
  /// Mint the unique bond token (also the A2A card id).
  Future<String> issueToken({required int seed, required String name});

  /// Forward the accepted charter to us + auto-host it. Returns the public URL.
  Future<String> forwardAndHostCharter({required String token, required String charter});
}

/// Local, deterministic implementation — no network required.
class LocalMoxService implements MoxService {
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32

  @override
  Future<String> issueToken({required int seed, required String name}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final r = Random(seed ^ name.hashCode);
    String chunk(int n) =>
        List.generate(n, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
    // Human-shaped + scannable: MOX·XXXX·XXXX·XXXX
    return 'MOX·${chunk(4)}·${chunk(4)}·${chunk(4)}';
  }

  @override
  Future<String> forwardAndHostCharter({required String token, required String charter}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // Real impl would POST {token, charter} to the backend; here we return the
    // deterministic public URL the backend would host it at.
    final slug = token.replaceAll('·', '').toLowerCase();
    return 'https://bond.justadestination.com/$slug';
  }
}

// --- To go live, drop in something like this and wire the base URL: ----------
//
// class RemoteMoxService implements MoxService {
//   final String baseUrl; final http.Client client;
//   RemoteMoxService(this.baseUrl, this.client);
//   Future<String> issueToken({required int seed, required String name}) async {
//     final res = await client.post(Uri.parse('$baseUrl/bond/token'),
//         body: jsonEncode({'seed': seed, 'name': name}));
//     return (jsonDecode(res.body) as Map)['token'] as String;
//   }
//   Future<String> forwardAndHostCharter({required String token, required String charter}) async {
//     final res = await client.post(Uri.parse('$baseUrl/bond/charter'),
//         body: jsonEncode({'token': token, 'charter': charter}));
//     return (jsonDecode(res.body) as Map)['url'] as String;
//   }
// }
