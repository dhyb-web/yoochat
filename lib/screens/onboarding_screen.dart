import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pseudo_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _S();
}

class _S extends State<OnboardingScreen> {
  final _c = PageController(); int _p = 0;
  final pages = const [
    (Icons.favorite_rounded, 'Parle à tes proches', 'Envoie des messages à tes proches, simplement.'),
    (Icons.photo_library_rounded, 'Partage tes moments', 'Photos, vidéos, vocaux. Partage tout, facilement.'),
    (Icons.public_rounded, 'Reste connecté', 'Discute avec ton équipe, où que tu sois.'),
  ];
  Future<void> _done() async {
    (await SharedPreferences.getInstance()).setBool('onboarded', true);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PseudoScreen()));
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(body: SafeArea(child: Column(children: [
      Align(alignment: Alignment.topRight, child: TextButton(onPressed: _done, child: const Text('Passer'))),
      Expanded(child: PageView.builder(controller: _c, itemCount: 3, onPageChanged: (i) => setState(() => _p = i),
        itemBuilder: (_, i) => Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(pages[i].$1, size: 120, color: cs.primary), const SizedBox(height: 32),
          Text(pages[i].$2, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), Text(pages[i].$3, textAlign: TextAlign.center),
        ])))),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 250), margin: const EdgeInsets.all(4),
        width: _p == i ? 24 : 8, height: 8,
        decoration: BoxDecoration(color: _p == i ? cs.primary : cs.outline, borderRadius: BorderRadius.circular(8))))),
      Padding(padding: const EdgeInsets.all(24), child: _p == 2
        ? FilledButton(onPressed: _done, child: const Text('Commencer'))
        : const SizedBox(height: 52)),
    ])));
  }
}
