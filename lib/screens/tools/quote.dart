import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../core/env.dart';

class QuoteTool extends StatefulWidget {
  const QuoteTool({super.key});
  @override
  State<QuoteTool> createState() => _S();
}

class _S extends State<QuoteTool> {
  late Future<Map> _f = _load(today: true);
  Future<Map> _load({bool today = false}) async {
    final r = await http.get(Uri.parse('https://zenquotes.io/api/${today ? 'today' : 'random'}'));
    if (r.statusCode != 200) throw 'http';
    return (jsonDecode(r.body) as List).first;
  }
  @override
  Widget build(BuildContext context) => FutureBuilder(future: _f, builder: (_, s) {
    if (s.hasError) return ErrorRetry(onRetry: () => setState(() => _f = _load()));
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final q = '« ${s.data!['q']} »\n— ${s.data!['a']}';
    return Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.format_quote_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
      Text(q, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic)),
      const SizedBox(height: 32),
      FilledButton(onPressed: () => setState(() => _f = _load()), child: const Text('Nouvelle citation')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () => Share.share(q), icon: const Icon(Icons.share), label: const Text('Partager')),
    ]));
  });
}
