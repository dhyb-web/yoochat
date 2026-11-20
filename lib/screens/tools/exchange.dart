import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/env.dart';

class ExchangeTool extends StatefulWidget {
  const ExchangeTool({super.key});
  @override
  State<ExchangeTool> createState() => _S();
}

class _S extends State<ExchangeTool> {
  // Taux par rapport à 1 EUR
  Map<String, double> rates = {'EUR': 1, 'XOF': 655.957, 'USD': 1.08};
  bool live = false; String from = 'XOF', to = 'EUR'; double amount = 10000;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    if (Env.exchange.isEmpty) return;
    try {
      final r = await http.get(Uri.parse('https://v6.exchangerate-api.com/v6/${Env.exchange}/latest/EUR'));
      final c = jsonDecode(r.body)['conversion_rates'];
      setState(() { rates = {'EUR': 1, 'XOF': (c['XOF'] as num).toDouble(), 'USD': (c['USD'] as num).toDouble()}; live = true; });
    } catch (_) {}
  }
  String _n(double v) => v.toStringAsFixed(v > 100 ? 0 : 2);
  @override
  Widget build(BuildContext context) {
    final res = amount / rates[from]! * rates[to]!;
    const labels = {'XOF': 'FCFA', 'EUR': 'Euro', 'USD': 'Dollar'};
    return ListView(padding: const EdgeInsets.all(20), children: [
      if (!live) const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Taux fixe, ajoute ta clé pour le taux en direct'))),
      if (live) const Text('Mis à jour aujourd\'hui', style: TextStyle(color: Colors.greenAccent)),
      ListTile(title: const Text('1 Euro'), trailing: Text('${_n(rates['XOF']!)} FCFA')),
      ListTile(title: const Text('1 Dollar'), trailing: Text('${_n(rates['XOF']! / rates['USD']!)} FCFA')),
      ListTile(title: const Text('1 Euro'), trailing: Text('${rates['USD']!.toStringAsFixed(3)} Dollar')),
      const Divider(height: 32),
      TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Montant'),
        onChanged: (v) => setState(() => amount = double.tryParse(v.replaceAll(' ', '')) ?? 0)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: DropdownButton(value: from, isExpanded: true, items: labels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => from = v!))),
        IconButton(onPressed: () => setState(() { final t = from; from = to; to = t; }), icon: const Icon(Icons.swap_horiz)),
        Expanded(child: DropdownButton(value: to, isExpanded: true, items: labels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => to = v!))),
      ]),
      const SizedBox(height: 16),
      Text('${_n(res)} ${labels[to]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
    ]);
  }
}
