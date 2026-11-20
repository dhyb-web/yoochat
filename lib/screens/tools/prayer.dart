import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/env.dart';

class PrayerTool extends StatefulWidget {
  const PrayerTool({super.key});
  @override
  State<PrayerTool> createState() => _S();
}

class _S extends State<PrayerTool> {
  late Future<Map> _f = _load(); Timer? _t;
  static const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Future<Map> _load() async {
    final r = await http.get(Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Lome&country=Togo&method=3'));
    if (r.statusCode != 200) throw 'http';
    return jsonDecode(r.body)['data']['timings'];
  }
  @override
  void initState() { super.initState(); _t = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {})); }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }
  DateTime _at(String hm) { final p = hm.split(':'); final n = DateTime.now(); return DateTime(n.year, n.month, n.day, int.parse(p[0]), int.parse(p[1])); }
  @override
  Widget build(BuildContext context) => FutureBuilder(future: _f, builder: (_, s) {
    if (s.hasError) return ErrorRetry(onRetry: () => setState(() => _f = _load()));
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final now = DateTime.now();
    var next = names.firstWhere((n) => _at(s.data![n]).isAfter(now), orElse: () => 'Fajr');
    var nextAt = _at(s.data![next]); if (!nextAt.isAfter(now)) nextAt = nextAt.add(const Duration(days: 1));
    final d = nextAt.difference(now);
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF2C5364)])),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Lomé', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        Text('Prochaine prière : $next', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text('dans ${d.inHours}h ${d.inMinutes % 60}min', textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 20)),
        const SizedBox(height: 24),
        for (final n in names) Card(color: n == next ? Colors.amber.withOpacity(.25) : Colors.white10, child: ListTile(
          title: Text(n, style: const TextStyle(color: Colors.white)),
          trailing: Text(s.data![n], style: const TextStyle(color: Colors.white, fontSize: 18)))),
      ]));
  });
}
