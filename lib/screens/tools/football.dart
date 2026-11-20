import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/env.dart';

class FootballTool extends StatefulWidget {
  const FootballTool({super.key});
  @override
  State<FootballTool> createState() => _S();
}

class _S extends State<FootballTool> {
  late Future<List> _f = _load(); String filter = 'Tous';
  Future<List> _load() async {
    final r = await http.get(Uri.parse('https://api.football-data.org/v4/matches'), headers: {'X-Auth-Token': Env.football});
    if (r.statusCode != 200) throw 'http';
    return jsonDecode(r.body)['matches'];
  }
  String _status(Map m) => switch (m['status']) {
    'IN_PLAY' || 'PAUSED' => 'En cours${m['minute'] != null ? " ${m['minute']}'" : ''}',
    'FINISHED' => 'Terminé',
    _ => 'À ${DateFormat.Hm().format(DateTime.parse(m['utcDate']).toLocal())}',
  };
  @override
  Widget build(BuildContext context) {
    if (Env.football.isEmpty) return const KeyMissing(keyName: 'FOOTBALL_API_KEY');
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8), child: SegmentedButton(segments: const [
        ButtonSegment(value: 'Tous', label: Text('Tous')), ButtonSegment(value: 'En cours', label: Text('En cours')),
        ButtonSegment(value: 'Terminés', label: Text('Terminés'))], selected: {filter}, onSelectionChanged: (s) => setState(() => filter = s.first))),
      Expanded(child: RefreshIndicator(onRefresh: () async => setState(() => _f = _load()), child: FutureBuilder(future: _f, builder: (_, s) {
        if (s.hasError) return ErrorRetry(onRetry: () => setState(() => _f = _load()));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final list = s.data!.where((m) => filter == 'Tous' || (filter == 'En cours' ? ['IN_PLAY', 'PAUSED'].contains(m['status']) : m['status'] == 'FINISHED')).toList();
        if (list.isEmpty) return ListView(children: const [SizedBox(height: 120), Center(child: Text('Aucun match'))]);
        return ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
          final m = list[i]; final sc = m['score']['fullTime'];
          Widget team(Map t) => Expanded(child: Column(children: [
            if (t['crest'] != null) Image.network(t['crest'], height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.shield)),
            Text(t['shortName'] ?? t['name'] ?? '', textAlign: TextAlign.center)]));
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            team(m['homeTeam']),
            Column(children: [Text('${sc['home'] ?? '-'} : ${sc['away'] ?? '-'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(_status(m))]),
            team(m['awayTeam']),
          ])));
        });
      }))),
    ]);
  }
}
