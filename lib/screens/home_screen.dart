import 'package:flutter/material.dart';
import 'chats_screen.dart';
import 'discover_screen.dart';
import 'channels_screen.dart';
import 'me_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _S();
}

class _S extends State<HomeScreen> {
  int _i = 0;
  final _pages = const [ChatsScreen(), DiscoverScreen(), ChannelsScreen(), MeScreen()];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _i, children: _pages),
    bottomNavigationBar: NavigationBar(selectedIndex: _i, onDestinationSelected: (i) => setState(() => _i = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: 'Discussions'),
      NavigationDestination(icon: Icon(Icons.explore_rounded), label: 'Découvrir'),
      NavigationDestination(icon: Icon(Icons.campaign_rounded), label: 'Chaînes'),
      NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Moi'),
    ]),
  );
}
