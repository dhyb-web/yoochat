import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesTool extends StatefulWidget {
  const NotesTool({super.key});
  @override
  State<NotesTool> createState() => _S();
}

class _S extends State<NotesTool> {
  List<String> notes = [];
  @override
  void initState() { super.initState(); SharedPreferences.getInstance().then((p) => setState(() => notes = p.getStringList('notes') ?? [])); }
  Future<void> _save() async => (await SharedPreferences.getInstance()).setStringList('notes', notes);
  Future<void> _add() async {
    final c = TextEditingController();
    final t = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Nouvelle note'),
      content: TextField(controller: c, maxLines: 5, autofocus: true),
      actions: [FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Enregistrer'))]));
    if (t != null && t.trim().isNotEmpty) { setState(() => notes.insert(0, t.trim())); _save(); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    body: notes.isEmpty ? const Center(child: Text('Aucune note. Touche + pour en ajouter.'))
      : ListView.builder(itemCount: notes.length, itemBuilder: (_, i) => Dismissible(
          key: ValueKey(notes[i] + i.toString()), onDismissed: (_) { setState(() => notes.removeAt(i)); _save(); },
          background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.all(16), child: const Icon(Icons.delete)),
          child: Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: ListTile(title: Text(notes[i]))))),
  );
}
