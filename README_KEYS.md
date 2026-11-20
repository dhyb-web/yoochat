# Où mettre tes clés (tout est gratuit)
1. Supabase : supabase.com > ton projet > Project Settings > API > copie "Project URL" et "anon public" dans SUPABASE_URL et SUPABASE_ANON_KEY.
2. Météo : openweathermap.org > My API keys > copie dans WEATHER_API_KEY. Taux : exchangerate-api.com > EXCHANGE_API_KEY. Foot : football-data.org > FOOTBALL_API_KEY.
3. IA : aistudio.google.com > Get API key (Gemini gratuit) > AI_API_KEY.
4. Firebase : installe FlutterFire (`dart pub global activate flutterfire_cli`) puis lance `flutterfire configure` : ça crée lib/firebase_options.dart tout seul.
5. Si une clé est vide, l'écran affiche "Ajoute ta clé dans .env" : l'appli ne plante jamais.

Base de données : ouvre Supabase > SQL Editor, colle supabase/schema.sql et clique Run.
Lancer : `flutter create .` (une seule fois, crée android/ios) puis `flutter pub get` puis `flutter run`.
