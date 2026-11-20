import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/env.dart';
import '../core/theme.dart';
import 'pseudo_screen.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});
  @override
  State<MeScreen> createState() => _S();
}

class _S extends State<MeScreen> {
  final db = Supabase.instance.client;
  late Future<Map<String, dynamic>> _f = db.from('profiles').select().eq('id', db.auth.currentUser!.id).single();

  Future<void> _editBio(String? bio) async {
    final c = TextEditingController(text: bio);
    final v = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Bio'),
      content: TextField(controller: c, maxLength: 150, maxLines: 3),
      actions: [FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK'))]));
    if (v == null) return;
    await db.from('profiles').update({'bio': v}).eq('id', db.auth.currentUser!.id);
    setState(() => _f = db.from('profiles').select().eq('id', db.auth.currentUser!.id).single());
  }

  Future<void> _recommend(String pseudo) async {
    final c = TextEditingController();
    final msg = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Donne ton avis'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(enabled: false, controller: TextEditingController(text: pseudo)),
        const SizedBox(height: 8), TextField(controller: c, maxLength: 500, maxLines: 4, decoration: const InputDecoration(hintText: 'Ton message'))]),
      actions: [FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Envoyer'))]));
    if (msg == null || msg.trim().isEmpty || !mounted) return;
    if (Env.siteUrl.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoute ta clé SITE_URL dans .env'))); return; }
    try {
      await http.post(Uri.parse('${Env.siteUrl}/api/recommandations'), headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pseudo': pseudo, 'message': msg, 'created_at': DateTime.now().toIso8601String()}));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci pour ta recommandation !')));
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérifie ta connexion'))); }
  }

  Future<void> _logout() async {
    await db.auth.signOut();
    final p = await SharedPreferences.getInstance(); await p.remove('pseudo'); await p.remove('session_token');
    if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PseudoScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(body: SafeArea(child: FutureBuilder(future: _f, builder: (_, s) {
    if (s.hasError) return ErrorRetry(onRetry: () => setState(() => _f = db.from('profiles').select().eq('id', db.auth.currentUser!.id).single()));
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final p = s.data!; final tc = context.watch<ThemeController>();
    return Column(children: [
      const SizedBox(height: 16),
      YooAvatar(name: p['pseudo'], url: p['photo_url'], size: 100),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(p['pseudo'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (p['is_verified'] == true) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, color: Colors.blue)),
      ]),
      GestureDetector(onTap: () => _editBio(p['bio']), child: Text(p['bio'] ?? 'Ajoute une bio ✏️')),
      const Padding(padding: EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock, color: Colors.greenAccent, size: 16), SizedBox(width: 4), Text('Connexion sécurisée', style: TextStyle(color: Colors.greenAccent))])),
      const TabBar(tabs: [Tab(text: 'Activité'), Tab(text: 'Paramètres')]),
      Expanded(child: TabBarView(children: [
        ListView(children: const [
          ListTile(leading: Icon(Icons.star), title: Text('Favoris')),
          ListTile(leading: Icon(Icons.history_toggle_off), title: Text('Mes statuts')),
          ListTile(leading: Icon(Icons.history), title: Text('Historique')),
        ]),
        ListView(children: [
          const ListTile(title: Text('Thème', style: TextStyle(fontWeight: FontWeight.bold))),
          for (var i = 0; i < themes.length; i++) RadioListTile(value: i, groupValue: tc.index, onChanged: (_) => tc.setTheme(i),
            title: Text(themes[i].name), secondary: CircleAvatar(backgroundColor: themes[i].primary, radius: 10)),
          const ListTile(leading: Icon(Icons.notifications), title: Text('Notifications')),
          ListTile(leading: const Icon(Icons.rate_review), title: const Text('Donne ton avis'), onTap: () => _recommend(p['pseudo'])),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text('Déconnexion'), onTap: _logout),
        ]),
      ])),
    ]);
  })))));
}
