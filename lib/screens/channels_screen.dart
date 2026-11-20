import 'package:flutter/material.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(
    appBar: AppBar(title: const Text('Chaînes', style: TextStyle(fontWeight: FontWeight.bold)),
      bottom: const TabBar(tabs: [Tab(text: 'Statuts'), Tab(text: 'Chaînes')])),
    body: const TabBarView(children: [
      Center(child: Text('Statuts 24h : prochaine étape (V1.1)')),
      Center(child: Text('Chaînes : prochaine étape (V1.1)')),
    ]),
  ));
}
