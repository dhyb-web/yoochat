import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/env.dart';
import 'tools_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 3, child: Scaffold(
    appBar: AppBar(title: const Text('Découvrir', style: TextStyle(fontWeight: FontWeight.bold)),
      bottom: const TabBar(tabs: [Tab(text: 'Actus'), Tab(text: 'Talents'), Tab(text: 'Outils')])),
    body: const TabBarView(children: [SiteList(endpoint: 'actus'), SiteList(endpoint: 'talents'), ToolsScreen()]),
  ));
}

class SiteList extends StatefulWidget {
  final String endpoint;
  const SiteList({super.key, required this.endpoint});
  @override
  State<SiteList> createState() => _SL();
}

class _SL extends State<SiteList> {
  late Future<List> _f = _load();
  Future<List> _load() async {
    final r = await http.get(Uri.parse('${Env.siteUrl}/api/${widget.endpoint}')).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw 'http';
    return jsonDecode(r.body) as List;
  }
  @override
  Widget build(BuildContext context) {
    if (Env.siteUrl.isEmpty) return const KeyMissing(keyName: 'SITE_URL');
    return FutureBuilder(future: _f, builder: (_, s) {
      if (s.hasError) return ErrorRetry(onRetry: () => setState(() => _f = _load()));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: s.data!.length, itemBuilder: (_, i) {
        final it = s.data![i] as Map;
        final talent = widget.endpoint == 'talents';
        return Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if ((it['image'] ?? it['photo']) != null) Image.network(it['image'] ?? it['photo'], height: 160, width: double.infinity, fit: BoxFit.cover),
          ListTile(title: Text(it['titre'] ?? it['title'] ?? it['nom'] ?? ''),
            subtitle: Text(talent ? '${it['metier'] ?? ''}\n${it['description'] ?? ''}' : (it['date'] ?? ''))),
          if (talent) Padding(padding: const EdgeInsets.all(12), child: FilledButton(onPressed: () {}, child: const Text('Discuter avec lui'))),
        ]));
      });
    });
  }
}
