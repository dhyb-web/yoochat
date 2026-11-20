import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _g(String k) { try { return dotenv.env[k]?.trim() ?? ''; } catch (_) { return ''; } }
  static String get supabaseUrl => _g('SUPABASE_URL');
  static String get supabaseAnonKey => _g('SUPABASE_ANON_KEY');
  static String get weather => _g('WEATHER_API_KEY');
  static String get exchange => _g('EXCHANGE_API_KEY');
  static String get football => _g('FOOTBALL_API_KEY');
  static String get ai => _g('AI_API_KEY');
  static String get siteUrl => _g('SITE_URL');
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Joli message quand une clé manque (l'appli ne plante jamais).
class MissingKeyScreen extends StatelessWidget {
  final String keyName;
  const MissingKeyScreen({super.key, required this.keyName});
  @override
  Widget build(BuildContext context) => Scaffold(body: KeyMissing(keyName: keyName));
}

class KeyMissing extends StatelessWidget {
  final String keyName;
  const KeyMissing({super.key, required this.keyName});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.vpn_key_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 16),
      Text('Ajoute ta clé $keyName dans .env', textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text('Voir README_KEYS.md', style: TextStyle(color: Colors.grey)),
    ]),
  ));
}

class ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const ErrorRetry({super.key, required this.onRetry, this.message = 'Vérifie ta connexion'});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, size: 48), const SizedBox(height: 12), Text(message),
    const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
  ]));
}
