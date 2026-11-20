import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/push_service.dart';
import 'home_screen.dart';

enum PState { idle, checking, invalid, taken, ok }

class PseudoScreen extends StatefulWidget {
  const PseudoScreen({super.key});
  @override
  State<PseudoScreen> createState() => _S();
}

class _S extends State<PseudoScreen> {
  final _ctrl = TextEditingController(); Timer? _deb; PState _st = PState.idle; bool _busy = false;
  static final _re = RegExp(r'^[A-Za-z0-9_.]{3,15}$');
  final db = Supabase.instance.client;

  void _onChange(String v) {
    _deb?.cancel();
    if (!_re.hasMatch(v)) { setState(() => _st = v.isEmpty ? PState.idle : PState.invalid); return; }
    setState(() => _st = PState.checking);
    _deb = Timer(const Duration(milliseconds: 500), () async {
      try {
        final r = await db.from('profiles').select('id').ilike('pseudo', v).maybeSingle();
        if (mounted && _ctrl.text == v) setState(() => _st = r == null ? PState.ok : PState.taken);
      } catch (_) { if (mounted) setState(() => _st = PState.idle); }
    });
  }

  Future<void> _enter() async {
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? const Uuid().v4();
    final token = const Uuid().v4();
    try {
      // Connexion anonyme Supabase : donne un vrai UUID sécurisé (auth.uid()).
      final auth = await db.auth.signInAnonymously();
      final uid = auth.user!.id;
      await db.from('profiles').insert({
        'id': uid, 'pseudo': _ctrl.text, 'device_id': deviceId, 'session_token': token,
        'last_active_at': DateTime.now().toIso8601String(),
      });
      await prefs.setString('device_id', deviceId);
      await prefs.setString('session_token', token);
      await prefs.setString('pseudo', _ctrl.text);
      await PushService.saveToken();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérifie ta connexion')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final (txt, col) = switch (_st) {
      PState.invalid => ('Pseudo invalide', Colors.redAccent),
      PState.taken => ('Ce pseudo est déjà pris', Colors.redAccent),
      PState.ok => ('Pseudo disponible', Colors.greenAccent),
      PState.checking => ('Vérification...', Colors.grey),
      PState.idle => ('3 à 15 caractères : lettres, chiffres, _ et .', Colors.grey),
    };
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('YooChat', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
        const Text('Discutez. Partagez. Avancez.', textAlign: TextAlign.center),
        const SizedBox(height: 40),
        TextField(controller: _ctrl, onChanged: _onChange, maxLength: 15,
          decoration: const InputDecoration(hintText: 'Ton pseudo', prefixIcon: Icon(Icons.alternate_email))),
        Text(txt, style: TextStyle(color: col)),
        const SizedBox(height: 24),
        FilledButton(onPressed: _st == PState.ok && !_busy ? _enter : null,
          child: _busy ? const CircularProgressIndicator() : const Text('Entrer')),
      ]))));
  }
}
