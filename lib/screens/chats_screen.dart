import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import 'chat_screen.dart';
import 'ai_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _S();
}

class _S extends State<ChatsScreen> {
  final db = Supabase.instance.client; String _q = '';
  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await db.from('conversation_participants')
        .select('is_pinned, conversations(id, type, name, avatar_url, last_message_at)')
        .eq('user_id', db.auth.currentUser!.id);
    final list = rows.map((r) => {...(r['conversations'] as Map<String, dynamic>), 'is_pinned': r['is_pinned']}).toList();
    list.sort((a, b) => (b['last_message_at'] ?? '').compareTo(a['last_message_at'] ?? ''));
    return list;
  }

  Future<void> _newChat() async {
    final c = TextEditingController();
    final pseudo = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Nouvelle discussion'),
      content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Pseudo (ou plusieurs, séparés par ,) ')),
      actions: [FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Créer'))]));
    if (pseudo == null || pseudo.trim().isEmpty) return;
    final names = pseudo.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final users = await db.from('profiles').select('id, pseudo').inFilter('pseudo', names);
    if (users.isEmpty) return;
    final conv = await db.from('conversations').insert({
      'type': users.length > 1 ? 'group' : 'private', 'name': users.length > 1 ? names.join(', ') : users.first['pseudo'],
    }).select().single();
    await db.from('conversation_participants').insert({'conversation_id': conv['id'], 'user_id': db.auth.currentUser!.id, 'role': 'admin'});
    for (final u in users) {
      await db.from('conversation_participants').insert({'conversation_id': conv['id'], 'user_id': u['id']});
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Discussions', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [IconButton(onPressed: _newChat, icon: const Icon(Icons.edit_square))]),
    // Yoo AI : bouton flottant (pas épinglé), icône étoile dégradée
    floatingActionButton: GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
      child: Container(width: 60, height: 60,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: myBubbleGradient,
          boxShadow: [BoxShadow(color: Color(0x886C5CE7), blurRadius: 18)]),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30))),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: TextField(
        onChanged: (v) => setState(() => _q = v.toLowerCase()),
        decoration: const InputDecoration(hintText: 'Rechercher', prefixIcon: Icon(Icons.search)))),
      Expanded(child: RefreshIndicator(onRefresh: () async => setState(() {}), child: FutureBuilder(
        future: _load(),
        builder: (_, s) {
          if (s.hasError) return ListView(children: const [SizedBox(height: 200), Center(child: Text('Vérifie ta connexion'))]);
          if (!s.hasData) return ListView(children: List.generate(6, (_) => const ListTile(
            leading: CircleAvatar(), title: SizedBox(height: 12, child: ColoredBox(color: Colors.white10)))));
          final list = s.data!.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(_q)).toList();
          if (list.isEmpty) return ListView(children: const [SizedBox(height: 200), Center(child: Text('Aucune discussion. Touche ✏️ pour commencer.'))]);
          return ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
            final c = list[i];
            final t = c['last_message_at'] != null ? DateFormat.Hm().format(DateTime.parse(c['last_message_at']).toLocal()) : '';
            return ListTile(
              leading: YooAvatar(name: c['name'] ?? '?', url: c['avatar_url'], size: 48),
              title: Text(c['name'] ?? ''), trailing: Text(t),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c['id'], title: c['name'] ?? ''))),
            );
          });
        }))),
    ]),
  );
}
