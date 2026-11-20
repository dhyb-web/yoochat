import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YooTheme {
  final String name; final Color bg; final Color primary; final Brightness brightness;
  const YooTheme(this.name, this.bg, this.primary, this.brightness);
}

const themes = [
  YooTheme('Sombre Premium', Color(0xFF1E1E2E), Color(0xFF6C5CE7), Brightness.dark),
  YooTheme('Clair', Color(0xFFF8F9FA), Color(0xFF6C5CE7), Brightness.light),
  YooTheme('Océan', Color(0xFF0A1628), Color(0xFF00BFFF), Brightness.dark),
  YooTheme('Forêt', Color(0xFF0F1F16), Color(0xFF00B894), Brightness.dark),
];

const myBubbleGradient = LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]);

class ThemeController extends ChangeNotifier {
  final SharedPreferences prefs;
  ThemeController(this.prefs);
  int get index => prefs.getInt('theme') ?? 0;
  void setTheme(int i) { prefs.setInt('theme', i); notifyListeners(); }
  ThemeData get themeData {
    final t = themes[index];
    final scheme = ColorScheme.fromSeed(seedColor: t.primary, brightness: t.brightness, primary: t.primary, surface: t.bg);
    return ThemeData(
      useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: t.bg,
      appBarTheme: AppBarTheme(backgroundColor: t.bg, elevation: 0),
      cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
      inputDecorationTheme: InputDecorationTheme(filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
    );
  }
}

/// Avatar rond : photo, sinon lettre + couleur auto basée sur le pseudo.
class YooAvatar extends StatelessWidget {
  final String name; final String? url; final double size;
  const YooAvatar({super.key, required this.name, this.url, this.size = 36});
  @override
  Widget build(BuildContext context) {
    final colors = [Colors.deepPurple, Colors.teal, Colors.orange, Colors.pink, Colors.blue, Colors.green];
    final c = colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
    return CircleAvatar(
      radius: size / 2, backgroundColor: c,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty)
          ? Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: size * .45, fontWeight: FontWeight.bold))
          : null,
    );
  }
}
