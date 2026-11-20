import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pseudo_screen.dart';
import 'screens/home_screen.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await dotenv.load(fileName: '.env'); } catch (_) {}
  if (Env.hasSupabase) {
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  }
  await PushService.init(); // ne plante pas si Firebase n'est pas configuré
  final prefs = await SharedPreferences.getInstance();
  runApp(ChangeNotifierProvider(
    create: (_) => ThemeController(prefs),
    child: YooChatApp(prefs: prefs),
  ));
}

class YooChatApp extends StatelessWidget {
  final SharedPreferences prefs;
  const YooChatApp({super.key, required this.prefs});
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    Widget start;
    if (!Env.hasSupabase) {
      start = const MissingKeyScreen(keyName: 'SUPABASE_URL et SUPABASE_ANON_KEY');
    } else if (!(prefs.getBool('onboarded') ?? false)) {
      start = const OnboardingScreen();
    } else if (Supabase.instance.client.auth.currentSession != null && prefs.getString('pseudo') != null) {
      start = const HomeScreen();
    } else {
      start = const PseudoScreen();
    }
    return MaterialApp(
      title: 'YooChat', debugShowCheckedModeBanner: false,
      theme: theme.themeData, home: start,
    );
  }
}
