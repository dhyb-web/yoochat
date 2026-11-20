import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/env.dart';

class WeatherTool extends StatefulWidget {
  const WeatherTool({super.key});
  @override
  State<WeatherTool> createState() => _S();
}

class _S extends State<WeatherTool> {
  late Future<Map> _f = _load();
  Future<Map> _load() async {
    final r = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=Lome,TG&units=metric&lang=fr&appid=${Env.weather}'));
    if (r.statusCode != 200) throw 'http';
    return jsonDecode(r.body);
  }
  @override
  Widget build(BuildContext context) {
    if (Env.weather.isEmpty) return const KeyMissing(keyName: 'WEATHER_API_KEY');
    return FutureBuilder(future: _f, builder: (_, s) {
      if (s.hasError) return ErrorRetry(onRetry: () => setState(() => _f = _load()));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final d = s.data!; final main = d['weather'][0]['main'];
      final icon = main == 'Clear' ? Icons.wb_sunny_rounded : main == 'Rain' ? Icons.water_drop_rounded : Icons.cloud_rounded;
      return ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Lomé', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Icon(icon, size: 100, color: Colors.amber),
        Text('${d['main']['temp'].round()}°C', textAlign: TextAlign.center, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800)),
        Text(d['weather'][0]['description'], textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ListTile(leading: const Icon(Icons.thermostat), title: const Text('Ressenti'), trailing: Text('${d['main']['feels_like'].round()}°C')),
        ListTile(leading: const Icon(Icons.water), title: const Text('Humidité'), trailing: Text('${d['main']['humidity']} %')),
        ListTile(leading: const Icon(Icons.air), title: const Text('Vent'), trailing: Text('${(d['wind']['speed'] * 3.6).round()} km/h')),
        FilledButton.icon(onPressed: () => setState(() => _f = _load()), icon: const Icon(Icons.refresh), label: const Text('Actualiser')),
      ]);
    });
  }
}
