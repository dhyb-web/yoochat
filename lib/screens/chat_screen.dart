import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId; final String title;
  const ChatScreen({super.key, required this.conversationId, required this.title});
  @override
  State<ChatScreen> createState() => _S();
}

class _S extends State<ChatScreen> {
  final db = Supabase.instance.client; final _ctrl = TextEditingController();
  late final String me = db.auth.currentUser!.id;
  late final Stream<List<Map<String, dynamic>>> _stream = db.from('messages')
      .stream(primaryKey: ['id']).eq('conversation_id', widget.conversationId).order('created_at', ascending: false);
  RealtimeChannel? _presence; bool _otherTyping = false; double? _progress;

  @override
  void initState() {
    super.initState();
    _presence = db.channel('typing:${widget.conversationId}')
      ..onBroadcast(event: 'typing', callback: (p) { if (p['uid'] != me && mounted) setState(() => _otherTyping = p['on'] == true); })
      ..subscribe();
    db.from('conversation_participants').update({'last_read_at': DateTime.now().toIso8601String()})
      .eq('conversation_id', widget.conversationId).eq('user_id', me);
    // Marquer comme lus les messages des autres (coches bleues)
    db.from('messages').update({'status': 'read'}).eq('conversation_id', widget.conversationId).neq('sender_id', me).neq('status', 'read');
  }

  @override
  void dispose() { if (_presence != null) db.removeChannel(_presence!); super.dispose(); }

  Future<void> _send({String type = 'text', String? text, String? url, int? size}) async {
    await db.from('messages').insert({'conversation_id': widget.conversationId, 'sender_id': me,
      'text': text, 'type': type, 'media_url': url, 'file_size': size});
    await db.from('conversations').update({'last_message_at': DateTime.now().toIso8601String()}).eq('id', widget.conversationId);
  }

  Future<void> _sendImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => _progress = 0.1);
    try {
      // Compression avant upload : max 1080p, JPG 75%
      final bytes = await FlutterImageCompress.compressWithFile(x.path, minWidth: 1080, minHeight: 1080, quality: 75);
      if (bytes == null) throw 'compress';
      setState(() => _progress = 0.5);
      final path = 'images/${const Uuid().v4()}.jpg';
      await db.storage.from('media').uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      await _send(type: 'image', url: db.storage.from('media').getPublicUrl(path), size: bytes.length);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Échec de l\'envoi'),
        action: SnackBarAction(label: 'Réessayer', onPressed: _sendImage)));
    } finally { if (mounted) setState(() => _progress = null); }
  }

  void _actions(Map<String, dynamic> m) {
    final mine = m['sender_id'] == me;
    final recent = DateTime.now().difference(DateTime.parse(m['created_at'])).inMinutes < 5;
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['❤️', '😂', '👍', '😮', '😢', '🙏'].map((e) => InkWell(onTap: () async {
          Navigator.pop(context);
          await db.from('message_reactions').upsert({'message_id': m['id'], 'user_id': me, 'emoji': e});
        }, child: Text(e, style: const TextStyle(fontSize: 28)))).toList())),
      ListTile(leading: const Icon(Icons.copy), title: const Text('Copier'), onTap: () {
        Clipboard.setData(ClipboardData(text: m['text'] ?? '')); Navigator.pop(context); }),
      ListTile(leading: const Icon(Icons.star), title: const Text('Favori'), onTap: () {
        db.from('messages').update({'is_starred': true}).eq('id', m['id']); Navigator.pop(context); }),
      if (mine && recent) ListTile(leading: const Icon(Icons.delete_forever), title: const Text('Supprimer pour tous'), onTap: () {
        db.from('messages').update({'is_deleted': true, 'text': null, 'media_url': null}).eq('id', m['id']); Navigator.pop(context); }),
    ])));
  }

  Widget _ticks(String? s) => switch (s) {
    'read' => const Icon(Icons.done_all, size: 16, color: Colors.lightBlueAccent),
    'delivered' => const Icon(Icons.done_all, size: 16, color: Colors.white70),
    _ => const Icon(Icons.done, size: 16, color: Colors.white70),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [
      YooAvatar(name: widget.title), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.title),
        if (_otherTyping) const Text('En train d\'écrire...', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
      ]),
    ])),
    body: Column(children: [
      if (_progress != null) LinearProgressIndicator(value: _progress),
      Expanded(child: StreamBuilder(stream: _stream, builder: (_, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final msgs = s.data!;
        return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: msgs.length, itemBuilder: (_, i) {
          final m = msgs[i]; final mine = m['sender_id'] == me;
          final deleted = m['is_deleted'] == true;
          return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: GestureDetector(
            onLongPress: deleted ? null : () => _actions(m),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
              decoration: BoxDecoration(gradient: mine ? myBubbleGradient : null,
                color: mine ? null : Colors.grey.shade300, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (deleted) const Text('🚫 Message supprimé', style: TextStyle(fontStyle: FontStyle.italic))
                else if (m['type'] == 'image' && m['media_url'] != null)
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(m['media_url']))
                else Text(m['text'] ?? '', style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(DateFormat.Hm().format(DateTime.parse(m['created_at']).toLocal()),
                    style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.black54)),
                  if (mine) ...[const SizedBox(width: 4), _ticks(m['status'])],
                ]),
              ])),
          ));
        });
      })),
      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        IconButton(onPressed: _sendImage, icon: const Icon(Icons.image_rounded)),
        Expanded(child: TextField(controller: _ctrl, minLines: 1, maxLines: 4,
          onChanged: (v) => _presence?.sendBroadcastMessage(event: 'typing', payload: {'uid': me, 'on': v.isNotEmpty}),
          decoration: const InputDecoration(hintText: 'Message'))),
        IconButton.filled(onPressed: () {
          final t = _ctrl.text.trim(); if (t.isEmpty) return;
          _ctrl.clear(); _send(text: t);
          _presence?.sendBroadcastMessage(event: 'typing', payload: {'uid': me, 'on': false});
        }, icon: const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );
}
