import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifications push Firebase (uniquement).
/// Après `flutterfire configure`, remplace Firebase.initializeApp() par
/// Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).
class PushService {
  static bool _ok = false;
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
      _ok = true;
    } catch (_) { _ok = false; } // Firebase pas encore configuré : l'appli continue.
  }
  static Future<void> saveToken() async {
    if (!_ok) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (token != null && uid != null) {
        await Supabase.instance.client.from('device_tokens').upsert({'user_id': uid, 'token': token});
      }
    } catch (_) {}
  }
}
