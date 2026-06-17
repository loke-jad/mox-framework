// llm.dart — the live agent's brain connection (OpenAI-compatible chat).
//
// Mirrors the framework runtime: plain /v1/chat/completions, so it works with the
// user's own key (BYOK), our hosted inference, or the minimal install-only
// allowance. Uses package:http so it runs on web AND native from one codebase.
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Where the onboarding/agent brain comes from on this install.
enum BrainSource { byok, hosted, allowance, none }

class BrainConfig {
  final BrainSource source;
  final String baseUrl; // includes /v1
  final String apiKey;
  final String model;
  const BrainConfig({
    required this.source,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  // Our endpoints (placeholders until the backend is wired). The allowance brain
  // is a small, install-only quota: enough to be walked through setup, no more.
  static const String hostedBase = 'https://brain.justadestination.com/v1';
  static const String hostedModel = 'mox-hosted';

  factory BrainConfig.byok({required String baseUrl, required String apiKey, required String model}) =>
      BrainConfig(source: BrainSource.byok, baseUrl: baseUrl, apiKey: apiKey, model: model);

  factory BrainConfig.hosted() => const BrainConfig(
      source: BrainSource.hosted, baseUrl: hostedBase, apiKey: '', model: hostedModel);

  /// Install-only allowance — same hosted endpoint, flagged + rate-limited backend-side.
  factory BrainConfig.allowance() => const BrainConfig(
      source: BrainSource.allowance, baseUrl: '$hostedBase/onboarding', apiKey: '', model: hostedModel);

  static const BrainConfig none =
      BrainConfig(source: BrainSource.none, baseUrl: '', apiKey: '', model: '');

  bool get usable => source != BrainSource.none && baseUrl.isNotEmpty && model.isNotEmpty;
}

class LlmClient {
  final BrainConfig cfg;
  LlmClient(this.cfg);

  /// One chat turn. [messages] are {role, content} maps. Returns the reply text.
  /// Throws on transport/HTTP error so the caller can fall back to the scripted flow.
  Future<String> chat(List<Map<String, String>> messages, {double temperature = 0.7}) async {
    if (!cfg.usable) throw Exception('no brain configured');
    final uri = Uri.parse('${cfg.baseUrl}/chat/completions');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (cfg.apiKey.isNotEmpty) 'Authorization': 'Bearer ${cfg.apiKey}',
          },
          body: jsonEncode({
            'model': cfg.model,
            'messages': messages,
            'temperature': temperature,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      final b = res.body;
      throw Exception('brain ${res.statusCode}: ${b.substring(0, b.length.clamp(0, 200))}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    return ((choices.first as Map)['message'] as Map)['content'] as String;
  }
}
