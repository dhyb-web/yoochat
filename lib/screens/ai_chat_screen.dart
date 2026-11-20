import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/env.dart';
import '../core/theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _S();
}

class _S extends State<AiChatScreen> {
  final _msgs = <(bool, String)>[(false, 'Salut ! Je suis Yoo AI. Comment je peux t\'aider ?')];
  final _ctrl = TextEditingController(); bool _busy = false;

  Future<void> _ask(String q) async {
    setState(() { _msgs.add((true, q)); _busy = true; });
    String answer;
    if (Env.ai.isEmpty) {
      answer = 'Ajoute ta clé AI_API_KEY dans .env';
    } else {
      try {
        final r = await http.post(Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${Env.ai}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {'parts': [{'text': 'Tu es Yoo AI. Réponds toujours en français simple et court.'}]},
            'contents': _msgs.map((m) => {'role': m.$1 ? 'user' : 'model', 'parts': [{'text': m.$2}]}).toList(),
          }));
        if (r.statusCode == 429) { answer = 'Réessaie dans quelques heures'; }
        else if (r.statusCode != 200) { answer = 'Oups, réessaie plus tard.'; }
        else { answer = jsonDecode(r.body)['candidates'][0]['content']['parts'][0]['text']; }
      } catch (_) { answer = 'Vérifie ta connexion'; }
    }
    if (mounted) setState(() { _msgs.add((false, answer)); _busy = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Row(children: [Icon(Icons.auto_awesome), SizedBox(width: 8), Text('Yoo AI')])),
    body: Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        for (final m in _msgs) Align(alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft, child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .8),
          decoration: BoxDecoration(gradient: m.$1 ? myBubbleGradient : null, color: m.$1 ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18)),
          child: Text(m.$2, style: TextStyle(color: m.$1 ? Colors.white : Colors.black87)))),
        if (_busy) const Padding(padding: EdgeInsets.all(8), child: Text('Yoo AI écrit...')),
      ])),
      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Pose ta question'))),
        IconButton.filled(onPressed: _busy ? null : () { final t = _ctrl.text.trim(); if (t.isNotEmpty) { _ctrl.clear(); _ask(t); } },
          icon: const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );
}
